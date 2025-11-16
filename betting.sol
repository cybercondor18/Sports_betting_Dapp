// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Betting {
    address public owner;

    struct Bet {
        address user;
        uint256 amount;
        bool forTeamA;
        bool claimed;
    }

    struct Match {
        bool exists;
        bool resolved;
        bool teamAWon;
        uint256 totalForA;
        uint256 totalForB;
    }

    mapping(uint256 => Match) public matches;
    mapping(uint256 => Bet[]) public matchBets;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createMatch(uint256 matchId) external onlyOwner {
        require(!matches[matchId].exists, "Match already exists");
        matches[matchId].exists = true;
    }

    function placeBet(uint256 matchId, bool forTeamA) external payable {
        require(matches[matchId].exists, "Match doesn't exist");
        require(!matches[matchId].resolved, "Match already resolved");
        require(msg.value > 0, "No ether sent");

        matchBets[matchId].push(Bet({
            user: msg.sender,
            amount: msg.value,
            forTeamA: forTeamA,
            claimed: false
        }));

        if (forTeamA) {
            matches[matchId].totalForA += msg.value;
        } else {
            matches[matchId].totalForB += msg.value;
        }
    }

    function resolveMatch(uint256 matchId, bool teamAWon) external onlyOwner {
        require(matches[matchId].exists, "Match doesn't exist");
        require(!matches[matchId].resolved, "Already resolved");

        matches[matchId].resolved = true;
        matches[matchId].teamAWon = teamAWon;
    }

    function claimWinnings(uint256 matchId) external {
        Match storage m = matches[matchId];
        require(m.exists && m.resolved, "Match not resolved");

        Bet[] storage bets = matchBets[matchId];
        uint256 totalPool = m.totalForA + m.totalForB;
        uint256 payout = 0;

        for (uint i = 0; i < bets.length; i++) {
            if (
                bets[i].user == msg.sender &&
                !bets[i].claimed &&
                bets[i].forTeamA == m.teamAWon
            ) {
                uint256 share = bets[i].amount;
                uint256 winSideTotal = m.teamAWon ? m.totalForA : m.totalForB;
                payout += (share * totalPool) / winSideTotal;
                bets[i].claimed = true;
            }
        }

        require(payout > 0, "No winnings to claim");
        payable(msg.sender).transfer(payout);
    }

    function getMatchPool(uint256 matchId) external view returns (uint256, uint256) {
        Match memory m = matches[matchId];
        return (m.totalForA, m.totalForB);
    }
}
