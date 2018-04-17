const RobofestCoin = artifacts.require("./RobofestCoin.sol")

module.exports = function(deployer) {
	deployer.deploy(RobofestCoin);
};