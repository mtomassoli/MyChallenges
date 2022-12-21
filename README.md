# Hacking Challenges

The challenges in this repository are all related to Ethereum hacking/security.
This may not be immediately apparent, but trust me on this! Sometimes you'll need to solve a challenge to understand why exactly it's security related.

**IMPORTANT:** No challenge requires advanced math, techniques, or tools to be solved, *unless explicitly stated*. In other words, you don't need to know *Convex Optimization*, advanced *Number Theory*, or use *SMT* solvers to solve the challenges, *unless explicitly stated*.

## Setup

You can install all the dependencies with

```shell
npm install
```

## How to play

Choose a challenge from the list of available challenges below. For instance, let's say you want to play the first one:

* [hashes] [hashChallenges.ts](test/hashChallenges.ts)

The term within square brackets is the *nickname*. To play it, **add** your solution to the file `test/hashChallenges.ts`, in the position indicated in the file itself, and then **test** your solution with

```shell
npm test hashes
```

which is equivalent to

```shell
npx hardhat test test/hashChallenges.ts
```

## Fair play

These challenges take place in a simulated environment, so you're given extra powers the use of which defeats the purpose of these challenges (with few exceptions, such as increasing the time by a moderate amount).
Also, you *MUST* only use the `player` or `attacker` account (whichever present). To be precise, you may add new accounts, but not impersonate the victim, the owner, the deployer, or any other accounts you wouldn't have access to in a real scenario.

Please do not spoil the challenges for others! Only people who are actively looking for the solutions should see them.

## Issues

I test the challenges as thoroughly as I can before releasing them, but mistakes do happen, as we all know. If you suspect there's something wrong with any of them, please let me know by opening an issue here on GitHub. I also read comments on reddit where I announce my challenges.

Be aware that issues on GitHub may contain spoilers. I think that's unavoidable. I'll try to fix serious bugs as soon as possible.

## Available challenges

* [hashes] [hashChallenges.ts](test/hashChallenges.ts)

*Happy coding/hacking!*
