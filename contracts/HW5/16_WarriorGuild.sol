// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title WarriorGuild
 * @dev Базовий абстрактний контракт для реєстрації воїнів.
 *      Підкласи Knight, Mage, Assassin реалізують унікальні механіки attack().
 */
abstract contract WarriorGuild {
    struct Warrior {
        string  name;
        uint256 health;
        uint256 attackPower;
        uint256 level;
        bool    isRegistered;
    }

    mapping(address => Warrior) public warriors;

    event WarriorRegistered(address indexed warrior, string name, string class);
    event AttackPerformed(address indexed warrior, uint256 damage, string attackType);

    /// @notice Зареєструвати воїна (реалізується у підкласі)
    function register(string calldata name) external virtual;

    /// @notice Атакувати (реалізується у підкласі з унікальною механікою)
    /// @return damage Завданий урон
    function attack() external virtual returns (uint256 damage);

    /// @notice Загальна логіка реєстрації — викликається з підкласів
    function _register(
        string calldata name,
        uint256 attackPower,
        string memory className
    ) internal {
        require(!warriors[msg.sender].isRegistered, "WarriorGuild: already registered");
        require(bytes(name).length > 0, "WarriorGuild: name cannot be empty");
        warriors[msg.sender] = Warrior({
            name:         name,
            health:       100,
            attackPower:  attackPower,
            level:        1,
            isRegistered: true
        });
        emit WarriorRegistered(msg.sender, name, className);
    }

    /// @notice Отримати інформацію про воїна
    function getWarrior(address addr) external view returns (Warrior memory) {
        return warriors[addr];
    }
}

// ─────────────────────────────────────────────────────────────────────────────

/**
 * @title Knight
 * @dev Важкий воїн: стабільний урон, здатність блокувати атаки щитом
 */
contract Knight is WarriorGuild {
    event ShieldBlocked(address indexed knight, uint256 blockedDamage);

    /// @notice Зареєструватися як Лицар (attackPower = 15)
    function register(string calldata name) external override {
        _register(name, 15, "Knight");
    }

    /// @notice Heavy Strike: damage = attackPower + level * 5
    function attack() external override returns (uint256 damage) {
        require(warriors[msg.sender].isRegistered, "WarriorGuild: not registered");
        Warrior storage w = warriors[msg.sender];
        damage = w.attackPower + w.level * 5;
        emit AttackPerformed(msg.sender, damage, "Heavy Strike");
    }

    /// @notice Унікальна здатність: заблокувати атаку щитом
    function shieldBlock() external {
        require(warriors[msg.sender].isRegistered, "WarriorGuild: not registered");
        uint256 blockedDamage = warriors[msg.sender].level * 10;
        emit ShieldBlocked(msg.sender, blockedDamage);
    }
}

// ─────────────────────────────────────────────────────────────────────────────

/**
 * @title Mage
 * @dev Маг: магічний множник урону, здатність кидати файрбол
 */
contract Mage is WarriorGuild {
    event FireballCast(address indexed mage, uint256 damage);

    /// @notice Зареєструватися як Маг (attackPower = 10)
    function register(string calldata name) external override {
        _register(name, 10, "Mage");
    }

    /// @notice Magic Bolt: damage = attackPower * 2
    function attack() external override returns (uint256 damage) {
        require(warriors[msg.sender].isRegistered, "WarriorGuild: not registered");
        damage = warriors[msg.sender].attackPower * 2;
        emit AttackPerformed(msg.sender, damage, "Magic Bolt");
    }

    /// @notice Унікальна здатність: файрбол (потрійний магічний урон)
    /// @return damage Урон від файрболу
    function castFireball() external returns (uint256 damage) {
        require(warriors[msg.sender].isRegistered, "WarriorGuild: not registered");
        damage = warriors[msg.sender].attackPower * 2 * 3;
        emit FireballCast(msg.sender, damage);
    }
}

// ─────────────────────────────────────────────────────────────────────────────

/**
 * @title Assassin
 * @dev Асасін: критичні удари та отрута
 */
contract Assassin is WarriorGuild {
    event PoisonApplied(address indexed assassin, address indexed target, uint256 poisonDamage);

    /// @notice Зареєструватися як Асасін (attackPower = 12)
    function register(string calldata name) external override {
        _register(name, 12, "Assassin");
    }

    /// @notice Quick/Critical Strike: 50% шанс подвійного урону
    /// @dev WARNING: небезпечний pseudo-random на основі block.timestamp, лише для навчальних цілей
    function attack() external override returns (uint256 damage) {
        require(warriors[msg.sender].isRegistered, "WarriorGuild: not registered");
        Warrior storage w = warriors[msg.sender];
        bool isCrit = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % 2 == 0;
        damage = isCrit ? w.attackPower * 2 : w.attackPower;
        string memory attackType = isCrit ? "Critical Strike" : "Quick Strike";
        emit AttackPerformed(msg.sender, damage, attackType);
    }

    /// @notice Унікальна здатність: нанести отруту цілі
    /// @param target Адреса цілі
    function poisonBlade(address target) external {
        require(warriors[msg.sender].isRegistered, "WarriorGuild: not registered");
        uint256 poisonDamage = warriors[msg.sender].attackPower / 2;
        emit PoisonApplied(msg.sender, target, poisonDamage);
    }
}
