import { ethers } from "ethers";

export function verifyPayment(
  contractAddress,
  amount,
  signature,
  expectedSender,
  escrowedBalance,
) {
  // Paso 1 — reconstruye el mensaje con la dirección del contrato
  const messageHash = ethers.solidityPackedKeccak256(
    ["address", "uint256"],
    [contractAddress, amount],
  );

  // Paso 2 — verifica que el monto sea el esperado
  // (esto lo hace Bob comparando con su propio registro)

  // Paso 3 — el monto no puede superar lo depositado
  if (amount > escrowedBalance) {
    return { valid: false, reason: "Amount exceeds escrowed balance" };
  }

  // Paso 4 — recupera quién firmó y lo compara con el sender esperado
  const recoveredAddress = ethers.verifyMessage(
    ethers.getBytes(messageHash),
    signature,
  );

  if (recoveredAddress.toLowerCase() !== expectedSender.toLowerCase()) {
    return { valid: false, reason: "Invalid signature" };
  }

  return { valid: true };
}
