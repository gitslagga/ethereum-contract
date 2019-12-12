pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;
  uint256 public cliff;
  uint256 public start;
  uint256 public duration;
  bool public revocable;

  mapping (address => uint256) private released;
  mapping (address => bool) private revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _start the time (as Unix time) at which point vesting starts
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    internal
  {
    require(_beneficiary != address(0), "TokenVesting: beneficiary can not be first address");
    require(_cliff <= _duration, "TokenVesting: duration time is before cliff time");

    beneficiary = _beneficiary;
    start = _start;
    cliff = _start.add(_cliff);
    duration = _duration;
    revocable = _revocable;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param _token IERC20 token which is being vested
   */
  function release(IERC20 _token) public {
    uint256 unreleased = releasableAmount(_token);
    require(unreleased > 0, "TokenVesting: no tokens to release");

    released[address(_token)] = released[address(_token)].add(unreleased);
    _token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param _token ERC20 token which is being vested
   */
  function revoke(IERC20 _token) public onlyOwner {
    require(revocable, "TokenVesting: can not be revocable");
    require(!revoked[address(_token)], "TokenVesting: tokens has been revoked");

    uint256 balance = _token.balanceOf(address(this));
    uint256 unreleased = releasableAmount(_token);
    uint256 refund = balance.sub(unreleased);

    revoked[address(_token)] = true;
    _token.safeTransfer(owner(), refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param _token IERC20 token which is being vested
   */
  function releasableAmount(IERC20 _token) private view returns (uint256) {
    return vestedAmount(_token).sub(released[address(_token)]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param _token ERC20 token which is being vested
   */
  function vestedAmount(IERC20 _token) private view returns (uint256) {
    uint256 currentBalance = _token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(released[address(_token)]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[address(_token)]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}