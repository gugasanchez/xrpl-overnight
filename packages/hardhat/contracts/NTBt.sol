//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// Useful for debugging. Remove when deploying to a live network.
import "hardhat/console.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "./math.sol";
import "./IBRLt.sol";

contract NTBt is ERC20Burnable, Ownable, DSMath {

  mapping(address => bool) public privilegedAccounts; // Privileged accounts (services and possibly banks)

  uint256 public immutable deployTimestamp;
  address public paymentToken; // Brazilian CBDC

  uint256 public immutable maxAmount;
  uint256 public immutable dueDate;
  bytes32 public immutable assetType;
  uint256 public minimumInvestment;
  uint256 public initialPrice;
  uint256 public interestRate;

  address public computeProfitContract;

  address[] public tokenOwners;
  mapping(address => uint256) public ownershipTimestamp;


	// Constructor: Called once on contract deployment
  constructor(
    string memory _name,
    string memory _symbol,
    uint256 _maxAmount,
    uint256 _initialPrice,
    uint256 _dueDate,
    uint256 _minimumInvestment,
    uint256 _interestRate,
    string memory _assetType,
    address _paymentToken
  ) ERC20(_name, _symbol) Ownable() {

    maxAmount = _maxAmount;
    initialPrice = _initialPrice;
    dueDate = _dueDate;
    minimumInvestment = _minimumInvestment;
    assetType = keccak256(bytes(_assetType));
    deployTimestamp = block.timestamp;
	paymentToken = _paymentToken;
    interestRate = _interestRate;

    privilegedAccounts[msg.sender] = true;
    privilegedAccounts[address(this)] = true;

  }

  function decimals() public view virtual override returns (uint8) {
        return 2;
  }

  modifier onlyPrivileged() {
    require(privilegedAccounts[msg.sender], "Access denied: account is not privileged.");
    _;
  }

  // Function to add an address to the list of privileged accounts
  function addPrivilegedAccount(address account) public onlyOwner {
      privilegedAccounts[account] = true;
  }

  // Function to remove an address from the list of privileged accounts
  function removePrivilegedAccount(address account) public onlyOwner {
      privilegedAccounts[account] = false;
  }

  // Function to transfer tokens from any account without requiring approval
  function privilegedTransfer(address from, address to, uint256 amount) public onlyPrivileged returns(bool) {
      _transfer(from, to, amount);
      return true;
  }

  function privilegedTransferReal(address _from, address _to, uint256 _amount) public onlyPrivileged {
    IBRLt(paymentToken).privilegedTransfer(_from, _to, _amount);
  }

  /**
   * @dev Transfers the specified amount of series tokens to the specified recipient.
   * @notice This function can only be called by the owner of the Debenture Token Contract.
   *
   * @param recipient The address of the recipient to transfer the series tokens to.
   * @param amount The amount of series tokens to transfer.
   * @return A boolean indicating whether the transfer was successful or not.
   */
  function transfer(address recipient, uint256 amount) public onlyOwner override returns (bool) {
    return super.transfer(recipient, amount);
  }

  /**
   * @dev Transfers the specified amount of series tokens from the sender's balance to the specified recipient.
   * @notice This function can only be called by the owner of the Debenture Token Contract.
   *
   * @param sender The address of the sender to transfer the series tokens from.
   * @param recipient The address of the recipient to transfer the series tokens to.
   * @param amount The amount of series tokens to transfer.
   * @return A boolean indicating whether the transfer was successful or not.
   */
  function transferFrom(address sender, address recipient, uint256 amount) public onlyOwner override returns (bool) {
    return super.transferFrom(sender, recipient, amount);
  }

      /**
     * @dev Returns the current token price for the series based on the current interest rate and the elapsed time since the series was deployed.
     * @notice The function calculates the number of compounding periods that have elapsed based on the current time and the due date of the series.
     * @notice It then calculates the current token price by multiplying the starting token price by (1 + interestRate) to the power of the number of compounding periods.
     * @notice If there is any remaining time that does not fall into a full compounding period, the function calculates the remaining interest for that time and adjusts the token price accordingly.
     * @return The current token price for the series.
     */
    function getTokenPrice() public view returns (uint256) {
        uint256 ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;
        uint256 price = WAD; // 1 * 10 ** 18

        uint256 interestRateWad = interestRate * 10 ** 14; // Convert to wad format (150 = 1.5% = 0.015)

        uint256 elapsedTime;
        if (block.timestamp > dueDate) {
            elapsedTime = dueDate - deployTimestamp;
        } else {
            elapsedTime = block.timestamp - deployTimestamp;
        }

        uint256 compoundingPeriods = elapsedTime / ONE_YEAR_IN_SECONDS;
        uint256 remainingTime = elapsedTime % ONE_YEAR_IN_SECONDS;

        for (uint256 i = 0; i < compoundingPeriods; i++) {
            price = wmul(price, add(WAD, interestRateWad));
        }

        if (remainingTime > 0) {
            uint256 remainingInterest = mul(interestRateWad, remainingTime) / ONE_YEAR_IN_SECONDS;
            uint256 remainingRate = add(WAD, remainingInterest);
            price = wmul(price, remainingRate);
        }

        return price;
    }

  /**
   * @dev Returns the current balance of the calling address in terms of the underlying interest token.
   * @notice The function first gets the current token price by calling the getTokenPrice() function.
   * @notice It then multiplies the balance of the calling wallet by the token price to get the current balance in terms of the interest token.
   * @return The current balance of the calling address in terms of the underlying interest token.
   */
  function getCurrentBalance(address _investor) public view returns (uint256) {
    uint256 tokenPrice = this.getTokenPrice();
    return this.balanceOf(_investor) * tokenPrice;
  }

  /**
   * @dev Sets the ownership timestamp of a specific investor to the current block timestamp.
   * @notice The function can only be called by the owner of the contract.
   * @param _investor The address of the investor whose ownership timestamp is being set.
   */
  function setOwnershipTimestamp(address _investor) public onlyOwner {
    ownershipTimestamp[_investor] = block.timestamp;
  }

  /**
   * @dev Adds the specified investor to the list of token owners.
   * @notice This function can only be called by the owner of the Debenture Token Contract.
   * @param _investor The address of the investor to add to the list of token owners.
   */
  function addToTokenOwners(address _investor) public onlyOwner {
    tokenOwners.push(_investor);
  }

  /**
   * @dev Adds the specified investor to the list of token owners.
   * @notice This function can only be called by the owner of the Debenture Token Contract.
   * @param _investor The address of the investor to add to the list of token owners.
   */
  function removeFromTokenOwners(address _investor) public onlyOwner {
    uint256 indexToRemove = tokenOwners.length;
    for (uint256 i = 0; i < tokenOwners.length; i++) {
        if (tokenOwners[i] == _investor) {
            indexToRemove = i;
            break;
        }
    }
    if (indexToRemove < tokenOwners.length) {
        delete tokenOwners[indexToRemove];
    }  
  }

  /**
   * @dev Returns the address from an specific array index.
   * @return Investor address stored in the index.
   */
  function getTokenOwners (uint32 index) public view returns (address) {
    return tokenOwners[index];
  }

  /**
   * @dev Returns the total number of token owners.
   * @return An unsigned integer representing the total number of token owners.
   */
  function tokenOwnersLength() external view virtual returns (uint256) {
    return tokenOwners.length;
  }

  function setMinimumInvestment (uint256 _minimumInvestment) public onlyOwner {
    minimumInvestment = _minimumInvestment;
  }

    /**
     * @dev Allows an investor to invest in a specific series by providing the series index and the investment value.
     * @notice If the series index is not valid, the function reverts with an InvalidSeriesIndex error.
     * @notice If the investment value is less than the minimum investment amount required for the series, the function reverts with an InvestmentValueBelowMinimumAmount error.
     * @notice If the series asset type is "coupon", the function checks whether the investor has already claimed interest within the last 30 days.
     * @notice If so, the function reverts with a MustClaimInterestToInvestAgain error.
     * @notice The function transfers the investment value in interest tokens from the investor to the contract address.
     * @notice It then calculates the amount of series tokens that the investor should receive based on the investment value and the current token price.
     * @notice If the investor does not already own any series tokens, the function sets the ownership timestamp for the investor.
     * @notice Finally, the function emits a NewInvestment event and returns true if the investment was successful.
     * @param investmentValue The value of the investment in interest tokens.
     * @return A boolean value indicating whether the investment was successful.
     */

	function invest(address investor, uint256 investmentValue) public onlyPrivileged returns (bool) {
        
        require(investmentValue >= minimumInvestment, "Invest minimum amount.");

        require(IBRLt(paymentToken).privilegedTransfer(investor, address(this), investmentValue), "Interest Token transaction failed.");
        
        uint256 tokenPrice = getTokenPrice();
        uint256 assetAmount = (investmentValue * WAD) / tokenPrice;
        uint256 assetRest = (investmentValue * WAD) % tokenPrice;
        uint256 totalAssetAmount = (((assetAmount * WAD) + (assetRest * WAD) / tokenPrice) / (WAD / 10 ** decimals()))/100;

        uint256 newSupply = totalSupply() + totalAssetAmount;
        require(newSupply < maxAmount, "Max amount!");
        _mint(investor, totalAssetAmount);

        if (ownershipTimestamp[investor] == 0) {
            setOwnershipTimestamp(investor);
        }

        addToTokenOwners(investor);

        return true;
    }

    function withdrawBacen() public onlyOwner returns (bool){
        uint256 contractBalance = IBRLt(paymentToken).balanceOf(address(this));
        IBRLt(paymentToken).transfer(msg.sender, contractBalance);

        return true;
  }

  function withdrawInvestor(address _investor, uint256 _BRLAmount) public onlyPrivileged returns (bool) {

    uint256 tokensAmount = (_BRLAmount * 10 ** 18) / getTokenPrice();
    privilegedTransfer(_investor, address(this), tokensAmount);
    privilegedTransferReal(address(this), _investor, _BRLAmount);

    return true;
  }
}