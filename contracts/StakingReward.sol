// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Staking {
  using SafeMath for uint256;
  IERC20 public stakingToken;
  IERC20 public rewardToken;

  mapping(address => uint256) balanceOf;

  mapping(address => uint256) rewardOf;

  mapping(address => uint256) rewardPerTokenPaid;

  uint256 public rewardPerTokenStored;
  uint256 public lastUpdatedTime;
  uint256 public rewardRate;
  uint256 public rewardDuration = 7 days;
  uint256 public periodFinish;
  uint256 public totalSupply;

  constructor(address _stakingToken, address _rewardToken) {
    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);

    lastUpdatedTime = block.timestamp;
  }

  modifier validAmount(uint256 _amount) {
    require(_amount > 0, "Amount must be greater than 0!");
    _;
  }

  modifier updateReward(address _account) {
    rewardPerTokenStored = getRewardPerTokenStored();
    lastUpdatedTime = _min(block.timestamp, periodFinish);
    rewardOf[_account] = earned(_account);
    rewardPerTokenPaid[_account] = rewardPerTokenStored;
    _;
  }

  function getRewardPerTokenStored() private view returns (uint256) {
    if (totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored +
      ((block.timestamp - lastUpdatedTime) * rewardRate * 1e18) /
      totalSupply;
  }

  function earned(address _account) public view returns (uint256) {
    uint256 currentRewardPerToken = getRewardPerTokenStored();
    uint256 pastReward = rewardOf[_account];

    return
      balanceOf[_account]
        .mul(currentRewardPerToken - rewardPerTokenPaid[_account])
        .div(1e18)
        .add(pastReward);
  }

  function stake(uint256 _amount) external validAmount(_amount) {
    totalSupply = totalSupply.add(_amount);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);

    bool success = stakingToken.transferFrom(
      msg.sender,
      address(this),
      _amount
    );

    if (!success) revert("Failed to transfer staked tokens!");
  }

  function claimReward(uint256 _amount) external validAmount(_amount) {
    require(rewardOf[msg.sender] >= _amount, "Not enough reward tokens!");
    rewardOf[msg.sender] -= _amount;
    bool success = rewardToken.transfer(msg.sender, _amount);
    if (!success) revert("Failed to claim reward!");
  }

  function withdraw(uint256 _amount) external validAmount(_amount) {
    require(balanceOf[msg.sender] >= _amount, "Not enough staked tokens!");
    balanceOf[msg.sender] -= _amount;
    bool success = stakingToken.transfer(msg.sender, _amount);
    if (!success) revert("Failed to withdraw tokens!");
  }

  function _min(uint256 v1, uint256 v2) internal pure returns (uint256) {
    return v1 > v2 ? v2 : v1;
  }
}
