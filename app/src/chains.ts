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
    bridge: "",
    usdc: "0xD2C27C38BeCB7FEeb6b36D291F54f24238267837",
    eth: "0xf88361c2b6ef95f83c1ce25f2119cf4493b14fd5",
  },
  "1442": {
    bridge: "",
    usdc: "0x9B417c6C7075a96Cd7B1e1757829dBf0A5CA8866",
    eth: "0xf88361C2b6Ef95F83C1ce25F2119Cf4493B14fD5",
  },
};
