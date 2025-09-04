# 🎓 Blockchain Credential Wallet

A decentralized system where schools issue tamper-proof certificates (degrees, diplomas, vocational badges) directly to student wallets. Employers can instantly verify authenticity without middlemen.

## 🚀 Features

- 🏫 **School Authorization**: Only authorized educational institutions can issue credentials
- 📜 **Tamper-Proof Certificates**: Immutable credential storage on blockchain
- ✅ **Instant Verification**: Employers can verify credentials without contacting schools
- 🔒 **Secure Storage**: Credentials linked to student wallet addresses
- 🚫 **Revocation Support**: Institutions can revoke invalid credentials
- 📊 **Verification Tracking**: Track who has verified each credential

## 📋 Contract Overview

The smart contract manages three main entities:
- **Authorized Issuers**: Educational institutions approved to issue credentials
- **Credentials**: Digital certificates with metadata and validation status
- **Verification Records**: Track when credentials are verified by third parties

## 🔧 Usage Instructions

### For Contract Owner

#### Add Authorized Issuer
```clarity
(contract-call? .Blockchain-Credential-Wallet add-authorized-issuer 'SP123... "Harvard University")
```

#### Deactivate Issuer
```clarity
(contract-call? .Blockchain-Credential-Wallet deactivate-issuer 'SP123...)
```

### For Educational Institutions

#### Issue Credential
```clarity
(contract-call? .Blockchain-Credential-Wallet issue-credential 
  'SP-STUDENT-ADDRESS...
  "Bachelor's Degree"
  "Bachelor of Science in Computer Science"
  "4-year undergraduate degree program"
  "{'gpa': '3.8', 'graduation_date': '2024-05-15', 'honors': 'magna cum laude'}")
```

#### Revoke Credential
```clarity
(contract-call? .Blockchain-Credential-Wallet revoke-credential u1)
```

### For Employers/Verifiers

#### Verify Credential
```clarity
(contract-call? .Blockchain-Credential-Wallet verify-credential u1)
```

#### Check Credential Validity
```clarity
(contract-call? .Blockchain-Credential-Wallet is-credential-valid u1)
```

## 🔍 Read-Only Functions

### Get Credential Details
```clarity
(contract-call? .Blockchain-Credential-Wallet get-credential u1)
```

### Get Credential with Issuer Info
```clarity
(contract-call? .Blockchain-Credential-Wallet get-credential-with-issuer u1)
```

### Check if Address is Authorized Issuer
```clarity
(contract-call? .Blockchain-Credential-Wallet is-authorized-issuer 'SP123...)
```

### Check if Recipient Has Credential
```clarity
(contract-call? .Blockchain-Credential-Wallet has-credential 'SP-STUDENT... u1)
```

## 📊 Data Structures

### Credential
- `recipient`: Student's wallet address
- `issuer-id`: ID of the issuing institution
- `credential-type`: Type of credential (e.g., "Bachelor's Degree")
- `title`: Full title of the credential
- `description`: Detailed description
- `metadata`: Additional data in JSON format
- `issued-at`: Block height when issued
- `is-revoked`: Revocation status

### Authorized Issuer
- `issuer-address`: Institution's wallet address
- `institution-name`: Name of the institution
- `is-active`: Active status
- `created-at`: Block height when authorized

## 🛡️ Security Features

- **Owner-Only Functions**: Only contract owner can authorize/deactivate issuers
- **Issuer Verification**: Only active authorized issuers can issue credentials
- **Revocation Control**: Only the issuing institution can revoke their credentials
- **Immutable Records**: Credentials cannot be modified, only revoked

## 🚦 Error Codes

- `u100`: Owner only operation
- `u101`: Not authorized issuer
- `u102`: Credential not found
- `u103`: Already exists
- `u104`: Invalid recipient
- `u105`: Credential revoked
- `u106`: Issuer not found

## 🔨 Development

### Prerequisites
- Clarinet
- Stacks blockchain development environment

### Testing
Run tests using Clarinet:
```bash
clarinet test
```

### Deployment
Deploy to testnet:
```bash
clarinet deploy --testnet
```

## 📝 License

MIT License - Feel free to use this contract for educational and commercial purposes.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

---

Built with ❤️ for the future of education verification
