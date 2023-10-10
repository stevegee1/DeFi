// SPDX-License-Identifier:MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EagleTokenReward.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    //type declaration
    using Math for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint amount;
        uint pendingReward;
    }
    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastBlockReward;
        uint256 rewardTokenPerShare;
    }

    //error declaration
    error MasterChef__duplicatePool();

    //state variables
    mapping(uint256 => mapping(address => UserInfo)) public s_userInfo;
    PoolInfo[] public s_poolInfoArray;
    address public s_dev;
    uint public s_EagleTokenPerBlock;
    uint public s_totalAllocation = 0;
    uint public s_startBlock;
    uint public s_BONUS_MULTIPLIER;
    EagleTokenReward public immutable I_EAG;
    UserInfo userInfo;

    constructor(
        EagleTokenReward _EAG,
        uint _eagtokenPerBlock,
        uint _startBlock,
        uint _multiplier,
        address _dev
    ) Ownable(msg.sender) {
        s_EagleTokenPerBlock = _eagtokenPerBlock;
        s_startBlock = _startBlock;
        s_BONUS_MULTIPLIER = _multiplier;
        s_dev = _dev;
        I_EAG = _EAG;

        s_poolInfoArray.push(
            PoolInfo({
                lpToken: _EAG,
                allocPoint: 10000,
                lastBlockReward: _startBlock,
                rewardTokenPerShare: 0
            })
        );
        s_totalAllocation = 10000;
    }

    function stake(uint pid, uint amount_staked) external {
        UserInfo storage user = s_userInfo[pid][msg.sender];
        user.amount += amount_staked;

        // //pending reward will be determined by amountStaked, bloffdiff, pointAllocation and total reward
        // //amount per each token share
        // user.pendingReward=;
    }

    // function addPool(
    //     uint pid,
    //     IERC20 _token,
    //     uint _alloc
    // ) external onlyOwner {
    //     PoolInfo storage pool = s_poolInfoArray[pid];
    //     pool.allocPoint = _alloc;
    //     pool.lpToken = _token;
    //     //waiting for when staking starts to calculate
    //     pool.lastBlockReward = (block.number >= s_startBlock)
    //         ? block.number
    //         : s_startBlock;
    //     pool.rewardTokenPerShare = 0;
    // }

    function getMultiplier(uint256 from, uint256 to)
        public
        view
        returns (uint)
    {
        (, uint x) = to.trySub(from);
        (, uint y) = x.tryMul(s_BONUS_MULTIPLIER);
        return y;
    }

    function updateMultiplier(uint _bonusMul) public {
        s_BONUS_MULTIPLIER = _bonusMul;
    }

    function poolLength() public view returns (uint) {
        return s_poolInfoArray.length;
    }

    function eachPoolInfor(uint pid) public view returns (PoolInfo memory) {
        return s_poolInfoArray[pid];
    }

    function checkPoolDuplicate(address _poolAdd) public view returns (bool x) {
        PoolInfo[] memory gasOptimization = s_poolInfoArray;
        for (uint i = 0; i < gasOptimization.length; i++) {
            if (address(gasOptimization[i].lpToken) == _poolAdd) {
                x = true;
            }
        }
        x = false;
    }

    function add(uint _allocPoint, IERC20 _lpToken) public onlyOwner {
        if (checkPoolDuplicate(address(_lpToken))) {
            revert MasterChef__duplicatePool();
        }
        (, s_totalAllocation) = s_totalAllocation.tryAdd(_allocPoint);
        uint _lastBlockReward= block.number > s_startBlock ? block.number : s_startBlock;
        s_poolInfoArray.push(PoolInfo({
            lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastBlockReward: _lastBlockReward,
                rewardTokenPerShare: 0

        }));
        updateStakingPool();
    }

    function updateStakingPool() internal {
        uint256 length = s_poolInfoArray.length;
        uint points = 0;
        for (uint pid = 1; pid < length; pid++) {
            (, points) = points.tryAdd(s_poolInfoArray[pid].allocPoint);
        }
        if (points != 0) {
            (, points) = points.tryDiv(3);
            (, uint t) = s_totalAllocation.trySub(
                s_poolInfoArray[0].allocPoint
            );
            (, s_totalAllocation) = t.tryAdd(points);
            s_poolInfoArray[0].allocPoint = points;
        }
    }
}
