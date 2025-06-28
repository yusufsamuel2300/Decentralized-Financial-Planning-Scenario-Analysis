;; Analysis Management Contract
;; Manages scenario analysis results and insights

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_ANALYSIS_NOT_FOUND (err u401))
(define-constant ERR_INVALID_PARAMETERS (err u402))
(define-constant ERR_DUPLICATE_ANALYSIS (err u403))

;; Data structures
(define-map analyses
  uint
  {
    simulation-id: uint,
    analyst: principal,
    title: (string-ascii 100),
    methodology: (string-ascii 200),
    key-findings: (list 10 (string-ascii 300)),
    recommendations: (list 10 (string-ascii 300)),
    risk-assessment: (string-ascii 500),
    confidence-level: uint,
    created-at: uint,
    peer-reviewed: bool,
    review-score: uint
  }
)

(define-map analysis-metrics
  uint
  {
    var-at-risk: int,
    expected-shortfall: int,
    sharpe-ratio: int,
    max-drawdown: int,
    correlation-matrix: (list 25 int),
    stress-test-results: (list 10 { scenario: (string-ascii 50), impact: int })
  }
)

(define-map peer-reviews
  { analysis-id: uint, reviewer: principal }
  {
    score: uint,
    comments: (string-ascii 500),
    methodology-rating: uint,
    accuracy-rating: uint,
    clarity-rating: uint,
    reviewed-at: uint
  }
)

(define-map analysis-tags
  uint
  (list 20 (string-ascii 50))
)

(define-data-var next-analysis-id uint u1)

;; Public functions
(define-public (create-analysis
  (simulation-id uint)
  (title (string-ascii 100))
  (methodology (string-ascii 200))
  (key-findings (list 10 (string-ascii 300)))
  (recommendations (list 10 (string-ascii 300)))
  (risk-assessment (string-ascii 500))
  (confidence-level uint)
)
  (let ((analysis-id (var-get next-analysis-id))
        (caller tx-sender))

    (asserts! (> (len title) u0) ERR_INVALID_PARAMETERS)
    (asserts! (<= confidence-level u100) ERR_INVALID_PARAMETERS)

    (map-set analyses analysis-id {
      simulation-id: simulation-id,
      analyst: caller,
      title: title,
      methodology: methodology,
      key-findings: key-findings,
      recommendations: recommendations,
      risk-assessment: risk-assessment,
      confidence-level: confidence-level,
      created-at: block-height,
      peer-reviewed: false,
      review-score: u0
    })

    (var-set next-analysis-id (+ analysis-id u1))
    (ok analysis-id)
  )
)

(define-public (add-analysis-metrics
  (analysis-id uint)
  (var-at-risk int)
  (expected-shortfall int)
  (sharpe-ratio int)
  (max-drawdown int)
  (correlation-matrix (list 25 int))
  (stress-test-results (list 10 { scenario: (string-ascii 50), impact: int }))
)
  (let ((analysis (unwrap! (map-get? analyses analysis-id) ERR_ANALYSIS_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get analyst analysis)) ERR_UNAUTHORIZED)

    (map-set analysis-metrics analysis-id {
      var-at-risk: var-at-risk,
      expected-shortfall: expected-shortfall,
      sharpe-ratio: sharpe-ratio,
      max-drawdown: max-drawdown,
      correlation-matrix: correlation-matrix,
      stress-test-results: stress-test-results
    })

    (ok true)
  )
)

(define-public (submit-peer-review
  (analysis-id uint)
  (score uint)
  (comments (string-ascii 500))
  (methodology-rating uint)
  (accuracy-rating uint)
  (clarity-rating uint)
)
  (let ((analysis (unwrap! (map-get? analyses analysis-id) ERR_ANALYSIS_NOT_FOUND))
        (reviewer tx-sender))

    (asserts! (not (is-eq reviewer (get analyst analysis))) ERR_UNAUTHORIZED)
    (asserts! (<= score u100) ERR_INVALID_PARAMETERS)
    (asserts! (<= methodology-rating u10) ERR_INVALID_PARAMETERS)
    (asserts! (<= accuracy-rating u10) ERR_INVALID_PARAMETERS)
    (asserts! (<= clarity-rating u10) ERR_INVALID_PARAMETERS)

    (map-set peer-reviews { analysis-id: analysis-id, reviewer: reviewer } {
      score: score,
      comments: comments,
      methodology-rating: methodology-rating,
      accuracy-rating: accuracy-rating,
      clarity-rating: clarity-rating,
      reviewed-at: block-height
    })

    ;; Update analysis review status
    (let ((avg-score (calculate-average-review-score analysis-id)))
      (map-set analyses analysis-id (merge analysis {
        peer-reviewed: true,
        review-score: avg-score
      }))
      (ok avg-score)
    )
  )
)

(define-public (tag-analysis (analysis-id uint) (tags (list 20 (string-ascii 50))))
  (let ((analysis (unwrap! (map-get? analyses analysis-id) ERR_ANALYSIS_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get analyst analysis)) ERR_UNAUTHORIZED)

    (map-set analysis-tags analysis-id tags)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-analysis (analysis-id uint))
  (map-get? analyses analysis-id)
)

(define-read-only (get-analysis-metrics (analysis-id uint))
  (map-get? analysis-metrics analysis-id)
)

(define-read-only (get-peer-review (analysis-id uint) (reviewer principal))
  (map-get? peer-reviews { analysis-id: analysis-id, reviewer: reviewer })
)

(define-read-only (get-analysis-tags (analysis-id uint))
  (map-get? analysis-tags analysis-id)
)

;; Private functions
(define-private (calculate-average-review-score (analysis-id uint))
  ;; Simplified calculation - in practice would iterate through all reviews
  u75 ;; Placeholder average score
)
