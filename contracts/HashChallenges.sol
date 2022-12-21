// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// IMPORTANT: Ignore frontrunning and similar attacks.
//
// YOUR GOAL: Get all the prize money (1110 ether)!
//   You can see test/hashChallenges.ts for the actual deployment scheme, but
//   the scheme is quite straightforward:
//     cproxy = new ChallengeProxy()
//     new HashChallenges{value: 1110 ether}(cproxy)
//   The idea is to play through cproxy. See function `play` in
//   test/hashChallenges.ts.

contract HashChallenges {
    ChallengeProxy cproxy;
    uint answer;

    constructor(ChallengeProxy cp) payable {
        uint easyPrize = 10 ether;
        uint mediumPrize = 100 ether;
        uint hardPrize = 1000 ether;
        require(
            msg.value == easyPrize + mediumPrize + hardPrize,
            "Wrong amount of ether"
        );

        cproxy = cp;

        // Easy Challenge:
        //  Find x such that
        //    hash(x) & 0xffff = 0x600d
        cp.addChallenge(
            "easy",
            abi.encodeWithSelector(HashChallenges.setAnswer.selector),
            abi.encodeWithSelector(
                HashChallenges.checkEasy.selector,
                0xffff,
                0x600d
            ),
            abi.encodeWithSelector(HashChallenges.getPrize.selector, easyPrize)
        );

        // Medium Challenge:
        //  Find x such that
        //    (
        //      (hash(x & (2^128 - 1)) | hash(x >> 128)) &
        //      x &
        //      0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f
        //    ) = 0x0208040a010502040a000b080c010400010004090401080200080a0500030002
        cp.addChallenge(
            "medium",
            abi.encodeWithSelector(HashChallenges.setAnswer.selector),
            abi.encodeWithSelector(
                HashChallenges.checkMedium.selector,
                0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f,
                0x0208040a010502040a000b080c010400010004090401080200080a0500030002
            ),
            abi.encodeWithSelector(
                HashChallenges.getPrize.selector,
                mediumPrize
            )
        );

        // Hard Challenge:
        //  Find x such that
        //    hash(x) = hash((x << 32) + 2) XOR
        //              hash((x << 64) + 4) XOR
        //              hash((x << 96) + 8) XOR
        //              hash((x << 128) + 16)
        cp.addChallenge(
            "hard",
            abi.encodeWithSelector(HashChallenges.setAnswer.selector),
            abi.encodeWithSelector(
                HashChallenges.checkHard.selector,
                [32, 2, 64, 4, 96, 8, 128, 16]
            ),
            abi.encodeWithSelector(HashChallenges.getPrize.selector, hardPrize)
        );
    }

    modifier onlyCProxy() {
        require(msg.sender == address(cproxy), "Only CProxy allowed");
        _;
    }

    function setAnswer(uint ans) external onlyCProxy {
        answer = ans;
    }

    function hash(uint x) internal pure returns (uint) {
        return uint(keccak256(abi.encode(x)));
    }

    // Check that
    //    hash(answer) & mask = val
    function checkEasy(
        uint mask,
        uint val
    ) external view returns (bool correct) {
        return (hash(answer) & mask) == val;
    }

    // Check that
    //    (hash(answer & (2^128 - 1)) | hash(answer >> 128)) &
    //       answer & mask = val
    function checkMedium(
        uint mask,
        uint val
    ) external view returns (bool correct) {
        uint hash_or = hash(answer & (2**128 - 1)) | hash(answer >> 128);
        return hash_or & answer & mask == val;
    }

    // Check that
    //   hash(answer) =
    //     hash((answer << vals[0]) + vals[1]) XOR
    //     hash((answer << vals[2]) + vals[3]) XOR
    //     ...
    function checkHard(
        uint[] calldata vals
    ) external view returns (bool correct) {
        uint res;
        for (uint i = 0; i + 1 < vals.length; i += 2) {
            res ^= hash((answer << vals[i]) + vals[i + 1]);
        }
        return res == hash(answer);
    }

    function getPrize(uint prize) external onlyCProxy {
        payable(msg.sender).transfer(prize);
    }
}

contract ChallengeProxy {
    struct Challenge {
        string name;
        address issuer;
        bytes setAnswerCD;          // CD = calldata
        bytes checkAnswerCD;
        bytes getPrizeCD;
        address winner;
        bool gotPrize;
    }

    // challenge name => challenge data
    mapping(string => Challenge) challenges;

    event Winner(string challengeName, address winner);

    receive() external payable {}

    function getWinner(string calldata name) public view returns (address) {
        Challenge storage c = challenges[name];
        require(c.issuer != address(0), "Challenge unknown");

        return c.winner;
    }

    function didIWin(string calldata name) external view returns (bool) {
        return getWinner(name) == msg.sender;
    }

    // The player will play by
    // 1. setting an answer
    // 2. checking the answer just set
    // 3. withdrawing the prize
    //
    // NOTE:
    //   The challenge issuer is always msg.sender.
    //   The use of calldatas allows for a very general interface.
    function addChallenge(
        string calldata name,
        bytes calldata setAnswerCD,         // CD = calldata
        bytes calldata checkAnswerCD,
        bytes calldata getPrizeCD
    ) external payable {
        Challenge storage c = challenges[name];
        require(c.issuer == address(0), "Challenge name unavailable");

        challenges[name] = Challenge(
            name,
            msg.sender,
            setAnswerCD,
            checkAnswerCD,
            getPrizeCD,
            address(0),
            false
        );
    }

    // IMPORTANT:
    //   `answer` must be the answer correctly encoded depending on the
    //   specific challenge.
    //   For example, if a challenge expects a uint, then one must use
    //     abi.encode(uint(x))              // solidity
    //     abi.encode(["uint256"], [x])     // ethers.js
    //
    // NOTE: Reentrancy is not a problem.
    function doChallenge(
        string calldata name,
        bytes calldata answer
    ) external returns (bool) {
        Challenge storage c = challenges[name];
        require(c.issuer != address(0), "Challenge unknown");
        require(c.winner == address(0), "Challenge already won");

        (bool success, ) = c.issuer.call(
            abi.encodePacked(c.setAnswerCD, answer)
        );
        require(success, "Couldn't set answer");

        bytes memory res;
        (success, res) = c.issuer.call(c.checkAnswerCD);
        require(success, "Couldn't check answer");

        if (abi.decode(res, (bool))) {
            c.winner = msg.sender;
            emit Winner(name, c.winner);
            return true;
        }
        return false;
    }

    // NOTE: Reentrancy is not a problem.
    function getPrize(string calldata name) external {
        Challenge storage c = challenges[name];
        require(c.issuer != address(0), "Challenge unknown");
        require(c.winner == msg.sender, "Caller didn't win");
        require(!c.gotPrize, "Already got prize");

        c.gotPrize = true;

        uint preBalance = address(this).balance;
        (bool success, ) = c.issuer.call(c.getPrizeCD);
        uint prize = address(this).balance - preBalance;
        require(success && prize > 0, "Couldn't get prize");

        payable(msg.sender).transfer(prize);
    }
}
