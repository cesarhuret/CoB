export const chains: any = {
  "11155111": {
    chainId: "0xaa36a7",
    chainIdNumber: "11155111",
    chainName: "Sepolia",
    rpcUrls: ["https://1rpc.io/sepolia"],
    nativeCurrency: {
      name: "ETH",
      symbol: "ETH",
      decimals: 18,
    },
  },
  "1442": {
    chainId: "0x5a2",
    chainIdNumber: "1442",
    chainName: "ZK EVM",
    rpcUrls: ["https://rpc.public.zkevm-test.net"],
    nativeCurrency: {
      name: "ETH",
      symbol: "ETH",
      decimals: 18,
    },
  },
};

export const deployments: any = {
  "11155111": {
    bridge: "0xE14c8eAAB11FC37fd5b52C4D1f878c4Bf5EAF628",
    usdc: "0xD2C27C38BeCB7FEeb6b36D291F54f24238267837",
    eth: "0xf88361c2b6ef95f83c1ce25f2119cf4493b14fd5",
    router: "0xd6c0AE992817AEd819777f960052eCAf4B90296c",
  },
  "1442": {
    bridge: "0x5156317aa1DF744b6291b0C4C08D0Dd3275589dC",
    usdc: "0x9B417c6C7075a96Cd7B1e1757829dBf0A5CA8866",
    eth: "0xf88361C2b6Ef95F83C1ce25F2119Cf4493B14fD5",
    router: "0x6e2542500d630b07D749C0a9D0C8CdF4e3359CcB",
  },
};
