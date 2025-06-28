;; Decision Support Contract
;; Provides decision-making support based on scenario analysis

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_DECISION_NOT_FOUND (err u501))
(define-constant ERR_INVALID_PARAMETERS (err u502))
(define-constant ERR_INSUFFICIENT_DATA (err u503))

;; Decision types
(define-constant DECISION_INVESTMENT u0)
(define-constant DECISION_RISK_MANAGEMENT u1)
(define-constant DECISION_PORTFOLIO_ALLOCATION u2)
(define-constant DECISION_STRATEGIC_PLANNING u3)

;; Data structures
(define-map decision-requests
  uint
  {
    requester: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    decision-type: uint,
    analysis-ids: (list 10 uint),
    criteria: (list 10 { name: (string-ascii 50), weight: uint }),
    constraints: (list 10 (string-ascii 200)),
    timeline: uint,
    created-at: uint,
    status: uint
  }
)

(define-map decision-recommendations
  uint
  {
    recommended-action: (string-ascii 300),
    rationale: (string-ascii 500),
    risk-level: uint,
    expected-outcome: (string-ascii 300),
    alternatives: (list 5 (string-ascii 200)),
    implementation-steps: (list 10 (string-ascii 200)),
    monitoring-metrics: (list 10 (string-ascii 100)),
    confidence-score: uint,
    generated-at: uint
  }
)

(define-map decision-outcomes
  uint
  {
    actual-outcome: (string-ascii 300),
    variance-from-expected: int,
    lessons-learned: (string-ascii 500),
    recommendation-accuracy: uint,
    recorded-at: uint,
    recorded-by: principal
  }
)

(define-map decision-voting
  { decision-id: uint, voter: principal }
  {
    vote: uint, ;; 0=against, 1=for, 2=abstain
    reasoning: (string-ascii 300),
    voted-at: uint
  }
)

(define-data-var next-decision-id uint u1)

;; Public functions
(define-public (create-decision-request
  (title (string-ascii 100))
  (description (string-ascii 500))
  (decision-type uint)
  (analysis-ids (list 10 uint))
  (criteria (list 10 { name: (string-ascii 50), weight: uint }))
  (constraints (list 10 (string-ascii 200)))
  (timeline uint)
)
  (let ((decision-id (var-get next-decision-id))
        (caller tx-sender))

    (asserts! (> (len title) u0) ERR_INVALID_PARAMETERS)
    (asserts! (<= decision-type u3) ERR_INVALID_PARAMETERS)
    (asserts! (> (len analysis-ids) u0) ERR_INSUFFICIENT_DATA)

    (map-set decision-requests decision-id {
      requester: caller,
      title: title,
      description: description,
      decision-type: decision-type,
      analysis-ids: analysis-ids,
      criteria: criteria,
      constraints: constraints,
      timeline: timeline,
      created-at: block-height,
      status: u0 ;; pending
    })

    (var-set next-decision-id (+ decision-id u1))
    (ok decision-id)
  )
)

(define-public (generate-recommendation
  (decision-id uint)
  (recommended-action (string-ascii 300))
  (rationale (string-ascii 500))
  (risk-level uint)
  (expected-outcome (string-ascii 300))
  (alternatives (list 5 (string-ascii 200)))
  (implementation-steps (list 10 (string-ascii 200)))
  (monitoring-metrics (list 10 (string-ascii 100)))
  (confidence-score uint)
)
  (let ((decision (unwrap! (map-get? decision-requests decision-id) ERR_DECISION_NOT_FOUND)))
    ;; In practice, would verify analyst credentials
    (asserts! (<= risk-level u100) ERR_INVALID_PARAMETERS)
    (asserts! (<= confidence-score u100) ERR_INVALID_PARAMETERS)

    (map-set decision-recommendations decision-id {
      recommended-action: recommended-action,
      rationale: rationale,
      risk-level: risk-level,
      expected-outcome: expected-outcome,
      alternatives: alternatives,
      implementation-steps: implementation-steps,
      monitoring-metrics: monitoring-metrics,
      confidence-score: confidence-score,
      generated-at: block-height
    })

    ;; Update decision status to "recommendation available"
    (map-set decision-requests decision-id (merge decision { status: u1 }))
    (ok true)
  )
)

(define-public (vote-on-decision
  (decision-id uint)
  (vote uint)
  (reasoning (string-ascii 300))
)
  (let ((decision (unwrap! (map-get? decision-requests decision-id) ERR_DECISION_NOT_FOUND))
        (voter tx-sender))

    (asserts! (<= vote u2) ERR_INVALID_PARAMETERS)

    (map-set decision-voting { decision-id: decision-id, voter: voter } {
      vote: vote,
      reasoning: reasoning,
      voted-at: block-height
    })

    (ok true)
  )
)

(define-public (record-outcome
  (decision-id uint)
  (actual-outcome (string-ascii 300))
  (variance-from-expected int)
  (lessons-learned (string-ascii 500))
  (recommendation-accuracy uint)
)
  (let ((decision (unwrap! (map-get? decision-requests decision-id) ERR_DECISION_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get requester decision)) ERR_UNAUTHORIZED)
    (asserts! (<= recommendation-accuracy u100) ERR_INVALID_PARAMETERS)

    (map-set decision-outcomes decision-id {
      actual-outcome: actual-outcome,
      variance-from-expected: variance-from-expected,
      lessons-learned: lessons-learned,
      recommendation-accuracy: recommendation-accuracy,
      recorded-at: block-height,
      recorded-by: tx-sender
    })

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-decision-request (decision-id uint))
  (map-get? decision-requests decision-id)
)

(define-read-only (get-decision-recommendation (decision-id uint))
  (map-get? decision-recommendations decision-id)
)

(define-read-only (get-decision-outcome (decision-id uint))
  (map-get? decision-outcomes decision-id)
)

(define-read-only (get-vote (decision-id uint) (voter principal))
  (map-get? decision-voting { decision-id: decision-id, voter: voter })
)

(define-read-only (calculate-decision-score (decision-id uint))
  ;; Simplified scoring based on analysis quality and consensus
  (let ((recommendation (map-get? decision-recommendations decision-id)))
    (match recommendation
      rec (get confidence-score rec)
      u0
    )
  )
)
