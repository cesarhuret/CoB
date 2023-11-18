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
    bridge: "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c",
    usdc: "0xB2AF72FD9f205457C7640bF7A77291746453550d",
    eth: "0x83F4CB0de9b89a4a623A7e96A79a99407Baa56Fd",
  },
  "1442": {
    bridge: "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d",
    usdc: "0xB2AF72FD9f205457C7640bF7A77291746453550d",
    eth: "0x68F6668b1211933a90B89f4dE0B445c0Ff3B2D1E",
  },
};
