// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title ResourceUtils
 * @dev Бібліотека для управління ігровими ресурсами:
 *      розподіл енергії, вартість апгрейдів, оптимізація витрат золота
 */
library ResourceUtils {
    /// @notice Розподілити енергію порівну між гравцями
    /// @param total      Загальна кількість енергії
    /// @param numPlayers Кількість гравців
    /// @return Енергія на одного гравця (цілочисельне ділення)
    function distributeEnergy(
        uint256 total,
        uint256 numPlayers
    ) internal pure returns (uint256) {
        require(numPlayers > 0, "ResourceUtils: no players to distribute");
        return total / numPlayers;
    }

    /// @notice Обчислити вартість апгрейду рівня
    /// @param base  Базова вартість
    /// @param level Рівень, на який здійснюється апгрейд
    /// @return Вартість = base * level * 150 / 100 (50% дорожче за кожен рівень)
    function calculateUpgradeCost(
        uint256 base,
        uint256 level
    ) internal pure returns (uint256) {
        require(level > 0, "ResourceUtils: level must be greater than zero");
        return (base * level * 150) / 100;
    }

    /// @notice Оптимізувати витрати золота
    /// @param gold     Доступне золото
    /// @param unitCost Вартість одного юніта
    /// @return units    Кількість юнітів, які можна купити
    /// @return remainder Залишок золота
    function optimizeGoldSpend(
        uint256 gold,
        uint256 unitCost
    ) internal pure returns (uint256 units, uint256 remainder) {
        require(unitCost > 0, "ResourceUtils: unit cost must be greater than zero");
        units = gold / unitCost;
        remainder = gold % unitCost;
    }
}

/**
 * @title ResourceManager
 * @dev Управляє ресурсами гравців, використовуючи бібліотеку ResourceUtils
 */
contract ResourceManager {
    address public owner;
    uint256 public constant UPGRADE_BASE_COST = 100;

    struct PlayerResources {
        uint256 energy;
        uint256 gold;
        uint256 level;
        bool    isRegistered;
    }

    mapping(address => PlayerResources) public players;
    address[] public participantList;

    event PlayerRegistered(address indexed player);
    event EnergyDistributed(uint256 totalEnergy, uint256 perPlayer, uint256 playerCount);
    event GoldEarned(address indexed player, uint256 amount, uint256 totalGold);
    event LevelUpgraded(address indexed player, uint256 newLevel, uint256 goldSpent);
    event GoldSpent(address indexed player, uint256 units, uint256 goldSpent, uint256 goldLeft);

    modifier onlyOwner() {
        require(msg.sender == owner, "ResourceManager: caller is not owner");
        _;
    }

    modifier onlyRegistered() {
        require(players[msg.sender].isRegistered, "ResourceManager: player not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Зареєструвати нового гравця (тільки власник)
    function registerPlayer(address player) external onlyOwner {
        require(player != address(0), "ResourceManager: zero address");
        require(!players[player].isRegistered, "ResourceManager: already registered");
        players[player] = PlayerResources({
            energy:       0,
            gold:         0,
            level:        1,
            isRegistered: true
        });
        participantList.push(player);
        emit PlayerRegistered(player);
    }

    /// @notice Розподілити енергію між усіма гравцями (тільки власник)
    function distributeEnergy(uint256 totalEnergy) external onlyOwner {
        require(totalEnergy > 0, "ResourceManager: totalEnergy must be greater than zero");
        uint256 count = participantList.length;
        uint256 perPlayer = ResourceUtils.distributeEnergy(totalEnergy, count);
        for (uint256 i = 0; i < count; i++) {
            players[participantList[i]].energy += perPlayer;
        }
        emit EnergyDistributed(totalEnergy, perPlayer, count);
    }

    /// @notice Нарахувати золото гравцю (тільки власник)
    function earnGold(address player, uint256 amount) external onlyOwner {
        require(players[player].isRegistered, "ResourceManager: player not registered");
        require(amount > 0, "ResourceManager: amount must be greater than zero");
        players[player].gold += amount;
        emit GoldEarned(player, amount, players[player].gold);
    }

    /// @notice Гравець апгрейдить свій рівень за золото
    function upgradeLevel() external onlyRegistered {
        PlayerResources storage p = players[msg.sender];
        uint256 nextLevel = p.level + 1;
        uint256 cost = ResourceUtils.calculateUpgradeCost(UPGRADE_BASE_COST, nextLevel);
        require(p.gold >= cost, "ResourceManager: insufficient gold for upgrade");
        p.gold -= cost;
        p.level = nextLevel;
        emit LevelUpgraded(msg.sender, nextLevel, cost);
    }

    /// @notice Гравець витрачає золото на покупку юнітів
    /// @param unitCost Вартість одного юніта
    /// @param quantity Бажана кількість юнітів
    function spendGold(uint256 unitCost, uint256 quantity) external onlyRegistered {
        PlayerResources storage p = players[msg.sender];
        (uint256 units, ) = ResourceUtils.optimizeGoldSpend(p.gold, unitCost);
        require(units >= quantity, "ResourceManager: not enough gold for requested quantity");
        uint256 totalCost = unitCost * quantity;
        p.gold -= totalCost;
        emit GoldSpent(msg.sender, quantity, totalCost, p.gold);
    }

    /// @notice Отримати ресурси гравця
    function getPlayer(address addr) external view returns (PlayerResources memory) {
        return players[addr];
    }

    /// @notice Кількість зареєстрованих гравців
    function getParticipantCount() external view returns (uint256) {
        return participantList.length;
    }
}
