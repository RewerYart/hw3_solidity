// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title IQuest
 * @dev Інтерфейс для управління квестами
 */
interface IQuest {
    function startQuest(uint256 questId) external;
    function completeQuest(uint256 questId) external;
    function getReward(uint256 questId) external returns (uint256);
}

/**
 * @title QuestManager
 * @dev Управляє квестами для гравців: реєстрація, проходження, нагороди та рівні
 */
contract QuestManager is IQuest {
    address public owner;
    uint256 public questCount;

    struct Quest {
        string  name;
        uint256 rewardAmount;
        uint256 xpReward;
        uint256 minLevel;
        bool    exists;
    }

    struct Player {
        bool    isRegistered;
        uint256 level;
        uint256 totalXP;
    }

    mapping(uint256 => Quest)                       public  quests;
    mapping(address => Player)                      public  players;
    mapping(address => mapping(uint256 => bool))    public  hasStarted;
    mapping(address => mapping(uint256 => bool))    public  hasCompleted;
    mapping(address => mapping(uint256 => bool))    private rewardClaimed;

    event QuestCreated(
        uint256 indexed questId,
        string name,
        uint256 rewardAmount,
        uint256 xpReward,
        uint256 minLevel
    );
    event QuestStarted(uint256 indexed questId, address indexed player);
    event QuestCompleted(uint256 indexed questId, address indexed player, uint256 xpEarned);
    event RewardClaimed(uint256 indexed questId, address indexed player, uint256 amount);
    event LeveledUp(address indexed player, uint256 newLevel);

    modifier onlyOwner() {
        require(msg.sender == owner, "QuestManager: caller is not owner");
        _;
    }

    modifier onlyRegistered() {
        require(players[msg.sender].isRegistered, "QuestManager: player not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Поповнення ETH-пулу нагород
    receive() external payable {}

    /// @notice Створити новий квест (тільки власник)
    /// @param name Назва квесту
    /// @param rewardAmount Нагорода у wei
    /// @param xpReward Кількість досвіду за виконання
    /// @param minLevel Мінімальний рівень гравця для початку
    /// @return questId Ідентифікатор створеного квесту
    function createQuest(
        string calldata name,
        uint256 rewardAmount,
        uint256 xpReward,
        uint256 minLevel
    ) external onlyOwner returns (uint256 questId) {
        require(bytes(name).length > 0, "QuestManager: name cannot be empty");
        require(rewardAmount > 0, "QuestManager: reward must be greater than zero");
        require(xpReward > 0, "QuestManager: xpReward must be greater than zero");
        require(minLevel >= 1, "QuestManager: minLevel must be at least 1");

        questId = questCount;
        quests[questId] = Quest({
            name:         name,
            rewardAmount: rewardAmount,
            xpReward:     xpReward,
            minLevel:     minLevel,
            exists:       true
        });
        questCount++;
        emit QuestCreated(questId, name, rewardAmount, xpReward, minLevel);
    }

    /// @notice Зареєструвати себе як гравця
    function registerPlayer() external {
        require(!players[msg.sender].isRegistered, "QuestManager: already registered");
        players[msg.sender] = Player({isRegistered: true, level: 1, totalXP: 0});
    }

    /// @notice Почати квест
    function startQuest(uint256 questId) external override onlyRegistered {
        Quest storage q = quests[questId];
        require(q.exists, "QuestManager: quest does not exist");
        require(!hasStarted[msg.sender][questId], "QuestManager: quest already started");
        require(
            players[msg.sender].level >= q.minLevel,
            "QuestManager: player level too low"
        );
        hasStarted[msg.sender][questId] = true;
        emit QuestStarted(questId, msg.sender);
    }

    /// @notice Завершити квест та отримати досвід
    function completeQuest(uint256 questId) external override onlyRegistered {
        require(hasStarted[msg.sender][questId], "QuestManager: quest not started");
        require(!hasCompleted[msg.sender][questId], "QuestManager: quest already completed");

        hasCompleted[msg.sender][questId] = true;

        Player storage p = players[msg.sender];
        uint256 xpEarned = quests[questId].xpReward;
        p.totalXP += xpEarned;

        // Підвищення рівня — один квест може дати XP для кількох рівнів
        while (p.totalXP >= (p.level + 1) * 100) {
            p.level++;
            emit LeveledUp(msg.sender, p.level);
        }

        emit QuestCompleted(questId, msg.sender, xpEarned);
    }

    /// @notice Отримати ETH-нагороду за виконаний квест
    /// @return amount Сума нагороди у wei
    function getReward(uint256 questId) external override onlyRegistered returns (uint256 amount) {
        require(hasCompleted[msg.sender][questId], "QuestManager: quest not completed");
        require(!rewardClaimed[msg.sender][questId], "QuestManager: reward already claimed");
        amount = quests[questId].rewardAmount;
        require(address(this).balance >= amount, "QuestManager: insufficient contract balance");

        rewardClaimed[msg.sender][questId] = true; // CEI: ефекти до взаємодії
        emit RewardClaimed(questId, msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    /// @notice Отримати інформацію про квест
    function getQuest(uint256 questId) external view returns (Quest memory) {
        return quests[questId];
    }

    /// @notice Отримати інформацію про гравця
    function getPlayer(address addr) external view returns (Player memory) {
        return players[addr];
    }

    /// @notice Баланс ETH-пулу нагород
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
