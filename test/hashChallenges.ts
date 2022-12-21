// Solidity dependencies:
//   contracts/HashChallenges.sol

import {ethers} from "hardhat";
import {expect} from "chai";
import {BigNumber} from "ethers";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {ChallengeProxy, HashChallenges} from "../typechain-types";

const utils = ethers.utils;
const abi = utils.defaultAbiCoder;
const getBalance = ethers.provider.getBalance;
const eth = utils.parseEther;

const EASY_PRIZE = eth("10");
const MEDIUM_PRIZE = eth("100");
const HARD_PRIZE = eth("1000");
const TOTAL_PRIZE = EASY_PRIZE.add(MEDIUM_PRIZE).add(HARD_PRIZE);

const prizeByName = new Map<string, BigNumber>([
    ["easy", EASY_PRIZE],
    ["medium", MEDIUM_PRIZE],
    ["hard", HARD_PRIZE]
]);

function encodeUint(x: any) {
    if (!BigNumber.isBigNumber(x)) x = BigNumber.from(x);
    return abi.encode(["uint256"], [x]);
}

function hashUint(x: any): BigNumber {
    if (!BigNumber.isBigNumber(x)) x = BigNumber.from(x);
    return BigNumber.from(utils.keccak256(encodeUint(x)));
}

describe('[Challenge] HashChallenges', function () {
    let player: SignerWithAddress;
    let pProxy: ChallengeProxy;
    let pChallenges: HashChallenges;
    let play: (name: string, answer: any) => Promise<void>;

    before(async function () {
        let deployer;
        [deployer, player] = await ethers.getSigners();

        const Proxy = await ethers.getContractFactory("ChallengeProxy", deployer);
        const proxy = await Proxy.deploy();

        const HashChallenges = await ethers.getContractFactory(
            "HashChallenges", deployer);
        const challenges = await HashChallenges.deploy(
            proxy.address, {value: TOTAL_PRIZE});

        pProxy = proxy.connect(player);
        pChallenges = challenges.connect(player);

        play = async (name: string, answer: any) => {
            // check that we won
            await pProxy.doChallenge(name, encodeUint(answer));
            const won = await pProxy.didIWin(name);
            expect(won).to.be.true;

            // check that we got paid
            const preBalance = await getBalance(player.address);
            await pProxy.getPrize(name);
            let prize = (await getBalance(player.address)).sub(preBalance);
            expect(prize).to.be.closeTo(prizeByName.get(name), eth("0.1"));
        }
    });

    // ---------------------- YOUR SOLUTION STARTS HERE ----------------------

    // You can send your answers with the function `play`, but that's neither
    // necessary nor necessarily sufficient ;)

    it('Easy Challenge', async function () {
        const easyAnswer = 0;
        await play("easy", easyAnswer);
    });

    it('Medium Challenge', async function () {
        const mediumAnswer = 0;
        await play("medium", mediumAnswer);
    });

    it('Hard Challenge', async function () {
        const hardAnswer = 0;
        await play("hard", hardAnswer);
    });

    // ----------------------- YOUR SOLUTION ENDS HERE -----------------------

    after(async function () {
        /**
         * YOUR OBJECTIVE: get all the prize money!
         */
        expect(await getBalance(pProxy.address)).to.equal(0);
    });
});
