;; an automated MiamiCoin mining pool/dao created by Asteria of the Syvita Guild

;; all rights to this code are reserved for the Stacks address:
;;      SP343J7DNE122AVCSC4HEK4MF871PW470ZSXJ5K66
;; as of Bitcoin block #688906 or the common era year 2021

;; error codes

;; constants

(define-constant IDLE_PHASE_CODE u0)
(define-constant PREPARE_PHASE_CODE u1)
(define-constant SPEND_PHASE_CODE u2)
(define-constant REDEEM_PHASE_CODE u3)

(define-constant PREPARE_PHASE_PERIOD u5)
(define-constant SPEND_PHASE_PERIOD u30)

;; asteria's address (asteria.btc)
(define-constant FEE_PRINCIPLE 'SP343J7DNE122AVCSC4HEK4MF871PW470ZSXJ5K66)

;; non-constants

(define-data-var currentPhase uint u0)
(define-data-var latestCycleId uint u0)

(define-map Cycles
    { id: uint } 
    { 
        totalParticipants: uint,
        totaluStxSpent: uint,
        preparePhaseStartedAt: uint,
        spendPhaseStartedAt: uint,
        preparePhaseFinishedAt: uint,
        spendPhaseFinishedAt: uint
    }
)

;; MAINNET: SP466FNC0P7JWTNM2R9T199QRZN1MYEDTAR0KP27
;; TESTNET: ST3CK642B6119EVC6CT550PW5EZZ1AJW6608HK60A

(define-constant miamiCoinContract 'ST3CK642B6119EVC6CT550PW5EZZ1AJW6608HK60A)

;; token

;; public functions

(define-public (start-prepare-phase)
    (begin
        (asserts! (is-eq (var-get currentPhase) IDLE_PHASE_CODE) (err u0))
        (asserts! 
            (map-insert
                Cycles
                { id: (+ (var-get latestCycleId) u1) }
                {
                    totalParticipants: u0,
                    totaluStxSpent: u0,
                    preparePhaseStartedAt: block-height,
                    spendPhaseStartedAt: u0,
                    preparePhaseFinishedAt: (+ block-height PREPARE_PHASE_PERIOD),
                    spendPhaseFinishedAt: u0
                }
            ) 
        (err u0))
        (var-set latestCycleId (+ (var-get latestCycleId) u1))
        (var-set currentPhase PREPARE_PHASE_CODE)
        (ok true)
    )
)

(define-public (start-spend-phase)
    (begin
        (asserts! (is-eq (var-get currentPhase) PREPARE_PHASE_CODE) (err u0))
        (asserts!
            (map-set
                Cycles
                { id: (var-get latestCycleId) }
                {
                    totalParticipants: (get totalParticipants (unwrap! (map-get? Cycles { id: (var-get latestCycleId) }) (err u0))),
                    totaluStxSpent: (get totaluStxSpent (unwrap! (map-get? Cycles { id: (var-get latestCycleId) }) (err u0))),
                    preparePhaseStartedAt: (get preparePhaseStartedAt (unwrap! (map-get? Cycles { id: (var-get latestCycleId) }) (err u0))),
                    spendPhaseStartedAt: block-height,
                    preparePhaseFinishedAt: (get preparePhaseFinishedAt (unwrap! (map-get? Cycles { id: (var-get latestCycleId) }) (err u0))),
                    spendPhaseFinishedAt: (+ block-height SPEND_PHASE_PERIOD)
                }
            )
        (err u0))
        (var-set currentPhase SPEND_PHASE_CODE)
        (ok true)
    )
)

(define-public (contribute-funds (amount uint))
    (begin
        (asserts! (is-eq (var-get currentPhase) PREPARE_PHASE_CODE) (err u0))
        (asserts! 
            (unwrap! 
                (stx-transfer? amount contract-caller (as-contract tx-sender))
                (err u0)
            ) 
            (err u0)
        )
        (ok true)
    )
)

(define-public (redeem-rewards)
    (ok true)
)

;; read-only functions

(define-read-only (get-latest-cycle-id)
    (ok (var-get latestCycleId))
)

(define-read-only (get-latest-cycle)
    (ok (map-get? Cycles { id: (var-get latestCycleId) }))
)

(define-read-only (get-previous-cycle (cycleId uint))
    (begin
        ;; if cycleId is latest cycle fail
        (asserts! (not (is-eq cycleId (var-get latestCycleId))) (err u0))
        (ok (map-get? Cycles {id: cycleId}))
    )
)

;; (contract-call? 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE.miamipool get-latest-cycle-id)