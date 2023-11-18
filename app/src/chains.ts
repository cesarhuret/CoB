export const chains: any = {
  "11155111": {
    chainId: "0xaa36a7",
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
    usdc: "0xD739ee77A41335d7f66AaA278a8bB228400d4Fc3",
    eth: "0x6f65b20F7A27997D48EC65C513EACe762487205a",
  },
};
