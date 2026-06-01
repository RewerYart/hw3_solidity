// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

/**
 * @title EducationalGrant
 * @dev Фонд освітніх грантів: студенти вносять кошти, власник підтверджує
 *      досягнення цілей і виплачує грант залежно від успішності.
 */
contract EducationalGrant {
    enum GrantStatus {
        Active,
        Completed,
        Frozen
    }

    struct Grant {
        address student;
        uint256 balance;
        uint8 performanceScore; // 0–100
        GrantStatus status;
        bool exists;
    }

    address public owner;
    mapping(address => Grant) public grants;

    event FundsDeposited(address indexed student, uint256 amount, uint256 totalBalance);
    event GoalCompleted(address indexed student, uint8 performanceScore);
    event GrantWithdrawn(address indexed student, uint256 amount);
    event GrantFrozen(address indexed student, string reason);
    event FundsReclaimed(address indexed student, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "EducationalGrant: caller is not owner");
        _;
    }

    modifier onlyStudent() {
        require(grants[msg.sender].exists, "EducationalGrant: caller is not a registered student");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Зареєструвати нового студента (тільки власник)
    function registerStudent(address student) external onlyOwner {
        require(student != address(0), "EducationalGrant: zero address");
        require(!grants[student].exists, "EducationalGrant: student already registered");
        grants[student] = Grant({
            student: student,
            balance: 0,
            performanceScore: 0,
            status: GrantStatus.Active,
            exists: true
        });
    }

    /// @notice Студент або родина вносить кошти на грант
    function deposit() external payable onlyStudent {
        require(
            grants[msg.sender].status == GrantStatus.Active,
            "EducationalGrant: grant is not active"
        );
        require(msg.value > 0, "EducationalGrant: amount must be greater than zero");
        grants[msg.sender].balance += msg.value;
        emit FundsDeposited(msg.sender, msg.value, grants[msg.sender].balance);
    }

    /// @notice Власник підтверджує виконання студентом навчальної цілі
    /// @param student Адреса студента
    /// @param score Оцінка успішності 0–100
    function completeGoal(address student, uint8 score) external onlyOwner {
        require(grants[student].exists, "EducationalGrant: student not registered");
        require(
            grants[student].status == GrantStatus.Active,
            "EducationalGrant: grant is not active"
        );
        require(score <= 100, "EducationalGrant: score must be between 0 and 100");
        grants[student].performanceScore = score;
        grants[student].status = GrantStatus.Completed;
        emit GoalCompleted(student, score);
    }

    /// @notice Студент знімає грант після підтвердження виконання цілі
    function withdraw() external onlyStudent {
        Grant storage g = grants[msg.sender];
        require(g.status == GrantStatus.Completed, "EducationalGrant: goal not completed");
        require(g.balance > 0, "EducationalGrant: nothing to withdraw");

        uint256 amount = calculateGrant(g.balance, g.performanceScore);
        g.balance = 0; // CEI: ефекти до взаємодії
        emit GrantWithdrawn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    /// @notice Власник заморожує грант студента (якщо умови не виконані)
    function freezeGrant(address student, string calldata reason) external onlyOwner {
        require(grants[student].exists, "EducationalGrant: student not registered");
        require(
            grants[student].status == GrantStatus.Active,
            "EducationalGrant: grant is not active"
        );
        grants[student].status = GrantStatus.Frozen;
        emit GrantFrozen(student, reason);
    }

    /// @notice Власник повертає заморожені кошти студенту
    function reclaimFunds(address student) external onlyOwner {
        require(grants[student].exists, "EducationalGrant: student not registered");
        require(
            grants[student].status == GrantStatus.Frozen,
            "EducationalGrant: grant is not frozen"
        );
        require(grants[student].balance > 0, "EducationalGrant: no funds to reclaim");

        uint256 amount = grants[student].balance;
        grants[student].balance = 0; // CEI: ефекти до взаємодії
        emit FundsReclaimed(student, amount);
        payable(student).transfer(amount);
    }

    /// @notice Отримати інформацію про грант студента
    function getGrant(address student) external view returns (Grant memory) {
        return grants[student];
    }

    /// @dev Розрахувати суму виплати залежно від успішності
    function calculateGrant(uint256 balance, uint8 score) internal pure returns (uint256) {
        return (balance * score) / 100;
    }
}
