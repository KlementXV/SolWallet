# SolWallet

This project provides a Docker image for managing Solana wallets.

## Getting Started

### Building the Docker Image

To build the Docker image, use the following command:

```bash
docker build --build-arg SOLANA_VERSION=<desired_version> -t solwallet .
```

Replace `<desired_version>` with the version of Solana you wish to install.

### Running the Docker Container

To run the Docker container, use the following command:

```bash
docker run -it --rm -e RPC=<mainnet|devnet> -v /path/to/local/wallets:/wallets ghcr.io/klementxv/solwallet:latest
```

- Replace `<mainnet|devnet>` with either `mainnet` or `devnet` depending on the network you want to connect to.
- Replace `/path/to/local/wallets` with the path to your local directory where wallet files will be stored.

**Warning:** Ensure you securely save all wallet files located in `/wallets`. The seed phrases and keys are critical for accessing your funds.

---