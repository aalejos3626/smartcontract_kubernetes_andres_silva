// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SmartContract_AndresSilva
 * @dev Contrato inteligente optimizado para práctica de orquestación en Kubernetes
 * @author Andrés Alejandro Silva Aguilar (UTPL)
 */
contract SmartContract_AndresSilva {
    uint256 public contadorTransaccional;
    string public autor = "Andres Alejandro Silva Aguilar";
    
    event TransaccionRegistrada(uint256 nuevoValor, string mensaje);

    function incrementarRegistro(string memory mensaje) public {
        contadorTransaccional += 1;
        emit TransaccionRegistrada(contadorTransaccional, mensaje);
    }

    function obtenerContador() public view returns (uint256) {
        return contadorTransaccional;
    }
}
