const { Wallet, Provider, utils } = require("zksync-web3");
const { HardhatRuntimeEnvironment } = require("hardhat/config");
const { ethers } = require("hardhat");
require("dotenv").config();

async function main() {
    const zkSyncProvider = new Provider("https://testnet.era.zksync.dev");
    const wallet = new Wallet(process.env.PRIVATE_KEY, zkSyncProvider);

    const artifact = await hre.artifacts.readArtifact("Betting");

    const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, wallet);
    const contract = await factory.deploy();

    await contract.deployed();

    console.log("✅ Betting contract deployed at:", contract.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});