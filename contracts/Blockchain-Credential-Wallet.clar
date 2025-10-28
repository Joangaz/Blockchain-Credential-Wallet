;; title: Blockchain-Credential-Wallet

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized-issuer (err u101))
(define-constant err-credential-not-found (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-recipient (err u104))
(define-constant err-credential-revoked (err u105))
(define-constant err-issuer-not-found (err u106))
(define-constant err-credential-expired (err u107))

(define-data-var next-credential-id uint u1)
(define-data-var next-issuer-id uint u1)

(define-map authorized-issuers
  { issuer-id: uint }
  {
    issuer-address: principal,
    institution-name: (string-ascii 100),
    is-active: bool,
    created-at: uint
  }
)

(define-map issuer-by-address
  { issuer-address: principal }
  { issuer-id: uint }
)

(define-map credentials
  { credential-id: uint }
  {
    recipient: principal,
    issuer-id: uint,
    credential-type: (string-ascii 50),
    title: (string-ascii 200),
    description: (string-ascii 500),
    metadata: (string-ascii 1000),
    issued-at: uint,
    is-revoked: bool,
    expires-at: (optional uint)
  }
)

(define-map recipient-credentials
  { recipient: principal, credential-id: uint }
  { exists: bool }
)

(define-map credential-verification
  { credential-id: uint, verifier: principal }
  { verified-at: uint }
)

(define-public (add-authorized-issuer (issuer-address principal) (institution-name (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (let ((issuer-id (var-get next-issuer-id)))
      (asserts! (is-none (map-get? issuer-by-address { issuer-address: issuer-address })) err-already-exists)
      (map-set authorized-issuers
        { issuer-id: issuer-id }
        {
          issuer-address: issuer-address,
          institution-name: institution-name,
          is-active: true,
          created-at: stacks-block-height
        }
      )
      (map-set issuer-by-address
        { issuer-address: issuer-address }
        { issuer-id: issuer-id }
      )
      (var-set next-issuer-id (+ issuer-id u1))
      (ok issuer-id)
    )
  )
)

(define-public (deactivate-issuer (issuer-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? issuer-by-address { issuer-address: issuer-address })
      issuer-data
      (let ((issuer-id (get issuer-id issuer-data)))
        (match (map-get? authorized-issuers { issuer-id: issuer-id })
          current-data
          (begin
            (map-set authorized-issuers
              { issuer-id: issuer-id }
              (merge current-data { is-active: false })
            )
            (ok true)
          )
          err-issuer-not-found
        )
      )
      err-issuer-not-found
    )
  )
)

(define-public (issue-credential 
  (recipient principal)
  (credential-type (string-ascii 50))
  (title (string-ascii 200))
  (description (string-ascii 500))
  (metadata (string-ascii 1000)))
  (let ((credential-id (var-get next-credential-id)))
    (match (map-get? issuer-by-address { issuer-address: tx-sender })
      issuer-data
      (let ((issuer-id (get issuer-id issuer-data)))
        (match (map-get? authorized-issuers { issuer-id: issuer-id })
          issuer-info
          (begin
            (asserts! (get is-active issuer-info) err-not-authorized-issuer)
            (map-set credentials
              { credential-id: credential-id }
              {
                recipient: recipient,
                issuer-id: issuer-id,
                credential-type: credential-type,
                title: title,
                description: description,
                metadata: metadata,
                issued-at: stacks-block-height,
                is-revoked: false,
                expires-at: none
              }
            )
            (map-set recipient-credentials
              { recipient: recipient, credential-id: credential-id }
              { exists: true }
            )
            (var-set next-credential-id (+ credential-id u1))
            (ok credential-id)
          )
          err-not-authorized-issuer
        )
      )
      err-not-authorized-issuer
    )
  )
)

(define-public (revoke-credential (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (match (map-get? issuer-by-address { issuer-address: tx-sender })
      issuer-data
      (let ((issuer-id (get issuer-id issuer-data)))
        (asserts! (is-eq issuer-id (get issuer-id credential-data)) err-not-authorized-issuer)
        (map-set credentials
          { credential-id: credential-id }
          (merge credential-data { is-revoked: true })
        )
        (ok true)
      )
      err-not-authorized-issuer
    )
    err-credential-not-found
  )
)

(define-public (verify-credential (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (begin
      (map-set credential-verification
        { credential-id: credential-id, verifier: tx-sender }
        { verified-at: stacks-block-height }
      )
      (ok credential-data)
    )
    err-credential-not-found
  )
)

(define-read-only (get-credential (credential-id uint))
  (map-get? credentials { credential-id: credential-id })
)

(define-read-only (get-credential-with-issuer (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (match (map-get? authorized-issuers { issuer-id: (get issuer-id credential-data) })
      issuer-data
      (ok {
        credential: credential-data,
        issuer: issuer-data
      })
      err-issuer-not-found
    )
    err-credential-not-found
  )
)

(define-read-only (get-issuer-info (issuer-address principal))
  (match (map-get? issuer-by-address { issuer-address: issuer-address })
    issuer-data
    (map-get? authorized-issuers { issuer-id: (get issuer-id issuer-data) })
    none
  )
)

(define-read-only (is-authorized-issuer (issuer-address principal))
  (match (get-issuer-info issuer-address)
    issuer-info (get is-active issuer-info)
    false
  )
)

(define-read-only (is-credential-valid (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (and
      (not (get is-revoked credential-data))
      (match (get expires-at credential-data)
        expiry-block (>= expiry-block stacks-block-height)
        true
      )
      (match (map-get? authorized-issuers { issuer-id: (get issuer-id credential-data) })
        issuer-data (get is-active issuer-data)
        false
      )
    )
    false
  )
)

(define-read-only (get-verification-history (credential-id uint))
  (map-get? credential-verification { credential-id: credential-id, verifier: tx-sender })
)

(define-read-only (has-credential (recipient principal) (credential-id uint))
  (is-some (map-get? recipient-credentials { recipient: recipient, credential-id: credential-id }))
)

(define-read-only (get-next-credential-id)
  (var-get next-credential-id)
)

(define-read-only (get-next-issuer-id)
  (var-get next-issuer-id)
)

(define-read-only (get-contract-owner)
  contract-owner
)

(define-public (set-credential-expiration (credential-id uint) (expiry-block uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (match (map-get? issuer-by-address { issuer-address: tx-sender })
      issuer-data
      (let ((issuer-id (get issuer-id issuer-data)))
        (asserts! (is-eq issuer-id (get issuer-id credential-data)) err-not-authorized-issuer)
        (asserts! (> expiry-block stacks-block-height) err-credential-expired)
        (map-set credentials
          { credential-id: credential-id }
          (merge credential-data { expires-at: (some expiry-block) })
        )
        (ok true)
      )
      err-not-authorized-issuer
    )
    err-credential-not-found
  )
)

(define-read-only (is-credential-expired (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data
    (match (get expires-at credential-data)
      expiry-block (< expiry-block stacks-block-height)
      false
    )
    false
  )
)

(define-read-only (get-credential-expiration (credential-id uint))
  (match (map-get? credentials { credential-id: credential-id })
    credential-data (get expires-at credential-data)
    none
  )
)
