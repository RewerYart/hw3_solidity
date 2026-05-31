// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title CommunityFunding
 * @dev Спільнота голосує за проекти; проект-переможець отримує фінансування
 */
contract CommunityFunding {
    struct Project {
        address proposer;
        string description;
        uint256 requiredAmount;
        uint256 voteCount;
        bool funded;
    }

    Project[] public projects;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    uint256 public totalFunds;

    event ProjectProposed(uint256 index, address proposer, string description, uint256 requiredAmount);
    event VoteCast(address voter, uint256 projectIndex);
    event FundsContributed(address contributor, uint256 amount);
    event FundsDistributed(uint256 projectIndex, address recipient, uint256 amount);

    /// @notice Запропонувати проект для фінансування
    /// @param description Опис проекту
    /// @param requiredAmount Необхідна сума у wei
    function proposeProject(string memory description, uint256 requiredAmount) public {
        require(bytes(description).length > 0, "CommunityFunding: description cannot be empty");
        require(requiredAmount > 0, "CommunityFunding: amount must be greater than zero");
        uint256 index = projects.length;
        projects.push(Project(msg.sender, description, requiredAmount, 0, false));
        emit ProjectProposed(index, msg.sender, description, requiredAmount);
    }

    /// @notice Проголосувати за проект
    /// @param projectIndex Індекс проекту у масиві
    function vote(uint256 projectIndex) public {
        require(projectIndex < projects.length, "CommunityFunding: invalid project index");
        require(!hasVoted[msg.sender][projectIndex], "CommunityFunding: already voted for this project");
        require(!projects[projectIndex].funded, "CommunityFunding: project already funded");
        hasVoted[msg.sender][projectIndex] = true;
        projects[projectIndex].voteCount++;
        emit VoteCast(msg.sender, projectIndex);
    }

    /// @notice Поповнити загальний фонд (надіслати ETH)
    function contribute() public payable {
        require(msg.value > 0, "CommunityFunding: contribution must be greater than zero");
        totalFunds += msg.value;
        emit FundsContributed(msg.sender, msg.value);
    }

    /// @notice Розподілити кошти: профінансувати проект з найбільшою кількістю голосів
    function distributeFunds() public {
        uint256 maxVotes = 0;
        uint256 winnerIndex = type(uint256).max;

        for (uint256 i = 0; i < projects.length; i++) {
            Project storage p = projects[i];
            if (!p.funded && p.voteCount > maxVotes && totalFunds >= p.requiredAmount) {
                maxVotes = p.voteCount;
                winnerIndex = i;
            }
        }

        require(winnerIndex != type(uint256).max, "CommunityFunding: no eligible project found");

        Project storage winner = projects[winnerIndex];
        winner.funded = true;
        totalFunds -= winner.requiredAmount;

        emit FundsDistributed(winnerIndex, winner.proposer, winner.requiredAmount);
        payable(winner.proposer).transfer(winner.requiredAmount);
    }

    /// @notice Отримати список усіх проектів
    /// @return Масив структур Project
    function getProjects() public view returns (Project[] memory) {
        return projects;
    }
}
