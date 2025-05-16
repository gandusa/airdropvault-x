(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-TOKEN (err u101))
(define-constant ERR-NO-STAKE (err u102))
(define-constant ERR-ALREADY-CLAIMED (err u103))
(define-constant ERR-NOT-ELIGIBLE (err u104))
(define-constant ERR-NOT-READY (err u105))

(define-data-var total-staked uint u0)
(define-data-var admin principal tx-sender)

(define-map user-stakes { user: principal } 
  { amount: uint, stake-height: uint })

(define-map airdrops 
  { token: principal, height: uint }
  { total: uint, claimed: uint })

(define-map user-claims 
  { user: principal, token: principal, height: uint }
  bool)

(define-trait sip-010-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-balance (principal) (response uint uint))
  )
)

;; ----------------------------
;; USER: Stake STX
;; ----------------------------
(define-public (stake (amount uint))
  (begin
    (asserts! (> amount u0) (err u100))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (let ((existing (map-get? user-stakes { user: tx-sender })))
      (if (is-some existing)
        (let ((current (unwrap! existing ERR-NO-STAKE)))
          (map-set user-stakes
            { user: tx-sender }
            {
              amount: (+ amount (get amount current)),
              stake-height: stacks-block-height
            }))
        (map-set user-stakes
          { user: tx-sender }
          { amount: amount, stake-height: stacks-block-height }))
      )
    (var-set total-staked (+ (var-get total-staked) amount))
    (ok true))
)

;; ----------------------------
;; USER: Unstake STX
;; ----------------------------
(define-public (unstake)
  (let ((user-data (map-get? user-stakes { user: tx-sender })))
    (match user-data user
      (begin
        ;; Optional: enforce lock-in duration
        (try! (stx-transfer? (get amount user) (as-contract tx-sender) tx-sender))
        (map-delete user-stakes { user: tx-sender })
        (var-set total-staked (- (var-get total-staked) (get amount user)))
        (ok true))
      ERR-NO-STAKE)
  )
)

;; ----------------------------
;; ADMIN: Schedule Airdrop
;; ----------------------------
(define-public (schedule-airdrop (token principal) (amount uint) (distribution-block uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-UNAUTHORIZED)
    (asserts! (> amount u0) (err u106))
    (asserts! (is-none (map-get? airdrops { token: token, height: distribution-block })) (err u107))
    (map-set airdrops { token: token, height: distribution-block }
      { total: amount, claimed: u0 })
    (ok true)
  )
)

;; ----------------------------
;; USER: Claim Airdrop
;; ----------------------------
(define-public (claim-airdrop (token <sip-010-trait>) (height uint))
  (let (
    (drop (map-get? airdrops { token: (contract-of token), height: height }))
    (user-stake-data (map-get? user-stakes { user: tx-sender }))
    (already-claimed (map-get? user-claims { user: tx-sender, token: (contract-of token), height: height }))
  )
    (begin
      (asserts! (is-some drop) ERR-INVALID-TOKEN)
      (asserts! (is-some user-stake-data) ERR-NOT-ELIGIBLE)
      (asserts! (is-none already-claimed) ERR-ALREADY-CLAIMED)
      (asserts! (>= stacks-block-height height) ERR-NOT-READY)
      
      (let (
        (drop-data (unwrap! drop ERR-INVALID-TOKEN))
        (user-stake (unwrap! user-stake-data ERR-NOT-ELIGIBLE))
        (user-share (/ (* (get total drop-data) (get amount user-stake)) (var-get total-staked)))
      )
        (map-set user-claims { user: tx-sender, token: (contract-of token), height: height } true)
        (map-set airdrops { token: (contract-of token), height: height }
          { total: (get total drop-data), claimed: (+ (get claimed drop-data) user-share) })
        
        (as-contract (contract-call? token transfer user-share tx-sender tx-sender))
      )
    )
  )
)

;; ----------------------------
;; READ-ONLY: Get Stake Info
;; ----------------------------
(define-read-only (get-user-stake (user principal))
  (default-to { amount: u0, stake-height: u0 } (map-get? user-stakes { user: user }))
)

(define-read-only (get-total-staked)
  (ok (var-get total-staked))
)
