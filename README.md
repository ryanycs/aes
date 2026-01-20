# AES

## Features

- Pipelined AES core supporting 128, 192, and 256-bit keys.
- AES-CTR mode for encryption/decryption.
- AES-GCM mode for authenticated encryption/decryption with associated data.

## Prerequisites

- GNU Make
- **Simulator**: Synopsys VCS or Mentor Graphics ModelSim.

## Running Tests

### RTL Simulation

#### List Available Tests

To see the list of available testbenches:

```bash
make list_tests
```

#### Run Simulation

You can run simulations using either VCS or ModelSim. The default key length is 128 bits.

**Using VCS:**

```bash
# Run AES core test
make test_aes.vcs

# Run with specific key length (e.g., 256 bits)
make test_aes.vcs KEY_LENGTH=256
```

**Using ModelSim:**

```bash
# Run AES core test
make test_aes.vsim

# Run with specific key length
make test_aes.vsim KEY_LENGTH=256
```

### Python Reference Tests

To verify the Python implementation against test vectors:

```bash
pytest
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.