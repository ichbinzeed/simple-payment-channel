import { ethers } from "ethers";

// Misma lógica que tu signPayment() en Foundry
export async function signPayment(contractAddress, amount, signer) {
  // Paso 1 — construye el mensaje (igual que abi.encodePacked en Solidity)
  const messageHash = ethers.solidityPackedKeccak256(
    ["address", "uint256"],
    [contractAddress, amount],
  );

  // Paso 2 — aplica prefijo Ethereum y firma
  // ethers.signMessage hace el prefijo automáticamente
  const signature = await signer.signMessage(ethers.getBytes(messageHash));

  return signature;
}
