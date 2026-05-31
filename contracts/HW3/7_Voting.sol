// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Voting
 * @dev Проста система голосування: список кандидатів, голосування, перегляд результатів
 */
contract Voting {
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;

    event Voted(address voter, uint256 candidateIndex);

    /// @notice Ініціалізація контракту зі списком кандидатів
    /// @param names Масив імен кандидатів
    constructor(string[] memory names) {
        require(names.length > 0, "Voting: no candidates provided");
        for (uint256 i = 0; i < names.length; i++) {
            candidates.push(Candidate(names[i], 0));
        }
    }

    /// @notice Проголосувати за кандидата
    /// @param index Індекс кандидата у масиві
    function vote(uint256 index) public {
        require(!hasVoted[msg.sender], "Voting: already voted");
        require(index < candidates.length, "Voting: invalid candidate index");
        hasVoted[msg.sender] = true;
        candidates[index].voteCount++;
        emit Voted(msg.sender, index);
    }

    /// @notice Отримати результати голосування
    /// @return Масив структур Candidate з іменами та кількістю голосів
    function getResults() public view returns (Candidate[] memory) {
        return candidates;
    }
}
