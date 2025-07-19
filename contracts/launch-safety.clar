;; Launch Safety Contract
;; Ensures new satellites avoid existing debris fields

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-DEBRIS-NOT-FOUND (err u101))
(define-constant ERR-LAUNCH-CONFLICT (err u105))
(define-constant ERR-INVALID-AGENCY (err u106))
(define-constant ERR-INVALID-TIMEFRAME (err u108))
(define-constant ERR-INSUFFICIENT-DATA (err u109))

;; Data Variables
(define-data-var next-clearance-id uint u1)
(define-data-var safety-buffer-distance uint u1000)
(define-data-var minimum-launch-window uint u3600)

;; Data Maps
(define-map launch-clearances
  { clearance-id: uint }
  {
    satellite-id: uint,
    launch-window-start: uint,
    launch-window-end: uint,
    trajectory-safe: bool,
    requesting-agency: principal,
    clearance-status: (string-ascii 20),
    approval-time: (optional uint),
    approving-agency: (optional principal),
    safety-conditions: (string-ascii 200),
    risk-assessment: (string-ascii 100),
    created-time: uint
  }
)

(define-map authorized-agencies
  { agency: principal }
  { authorized: bool, launch-authority: bool }
)

(define-map exclusion-zones
  { zone-id: uint }
  {
    center-x: int,
    center-y: int,
    center-z: int,
    radius: uint,
    zone-type: (string-ascii 30),
    active-until: uint,
    created-by: principal,
    reason: (string-ascii 100)
  }
)

(define-map satellite-trajectories
  { satellite-id: uint }
  {
    launch-position-x: int,
    launch-position-y: int,
    launch-position-z: int,
    target-position-x: int,
    target-position-y: int,
    target-position-z: int,
    trajectory-type: (string-ascii 30),
    launch-velocity: uint,
    estimated-flight-time: uint
  }
)

(define-map safety-violations
  { violation-id: uint }
  {
    clearance-id: uint,
    violation-type: (string-ascii 50),
    debris-id: uint,
    minimum-distance: uint,
    violation-time: uint,
    severity: (string-ascii 20)
  }
)

;; Authorization Functions
(define-public (authorize-agency (agency principal) (launch-authority bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-agencies
      { agency: agency }
      { authorized: true, launch-authority: launch-authority }))
  )
)

(define-public (set-safety-parameters (buffer-distance uint) (min-window uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> buffer-distance u0) ERR-INSUFFICIENT-DATA)
    (asserts! (> min-window u0) ERR-INSUFFICIENT-DATA)
    (var-set safety-buffer-distance buffer-distance)
    (var-set minimum-launch-window min-window)
    (ok true)
  )
)

;; Read Functions
(define-read-only (is-authorized-agency (agency principal))
  (default-to false (get authorized (map-get? authorized-agencies { agency: agency })))
)

(define-read-only (has-launch-authority (agency principal))
  (default-to false (get launch-authority (map-get? authorized-agencies { agency: agency })))
)

(define-read-only (get-launch-clearance (clearance-id uint))
  (map-get? launch-clearances { clearance-id: clearance-id })
)

(define-read-only (get-exclusion-zone (zone-id uint))
  (map-get? exclusion-zones { zone-id: zone-id })
)

(define-read-only (get-satellite-trajectory (satellite-id uint))
  (map-get? satellite-trajectories { satellite-id: satellite-id })
)

(define-read-only (get-safety-parameters)
  {
    buffer-distance: (var-get safety-buffer-distance),
    minimum-window: (var-get minimum-launch-window)
  }
)

(define-read-only (get-safety-violation (violation-id uint))
  (map-get? safety-violations { violation-id: violation-id })
)

;; Write Functions
(define-public (request-launch-clearance
  (satellite-id uint) (launch-window-start uint) (launch-window-end uint)
  (requesting-agency principal) (launch-pos-x int) (launch-pos-y int) (launch-pos-z int)
  (target-pos-x int) (target-pos-y int) (target-pos-z int)
  (trajectory-type (string-ascii 30)) (launch-velocity uint))
  (let ((clearance-id (var-get next-clearance-id)))
    (begin
      (asserts! (is-authorized-agency tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> launch-window-start block-height) ERR-INVALID-TIMEFRAME)
      (asserts! (> launch-window-end launch-window-start) ERR-INVALID-TIMEFRAME)
      (asserts! (>= (- launch-window-end launch-window-start) (var-get minimum-launch-window)) ERR-INVALID-TIMEFRAME)
      (asserts! (> launch-velocity u0) ERR-INSUFFICIENT-DATA)

      ;; Store satellite trajectory
      (map-set satellite-trajectories
        { satellite-id: satellite-id }
        {
          launch-position-x: launch-pos-x,
          launch-position-y: launch-pos-y,
          launch-position-z: launch-pos-z,
          target-position-x: target-pos-x,
          target-position-y: target-pos-y,
          target-position-z: target-pos-z,
          trajectory-type: trajectory-type,
          launch-velocity: launch-velocity,
          estimated-flight-time: (calculate-flight-time launch-pos-x launch-pos-y launch-pos-z
                                                       target-pos-x target-pos-y target-pos-z launch-velocity)
        }
      )

      ;; Perform initial safety assessment
      (let ((safety-check (assess-trajectory-safety satellite-id launch-window-start launch-window-end)))
        (map-set launch-clearances
          { clearance-id: clearance-id }
          {
            satellite-id: satellite-id,
            launch-window-start: launch-window-start,
            launch-window-end: launch-window-end,
            trajectory-safe: (get safe safety-check),
            requesting-agency: requesting-agency,
            clearance-status: "pending",
            approval-time: none,
            approving-agency: none,
            safety-conditions: (get conditions safety-check),
            risk-assessment: (get assessment safety-check),
            created-time: block-height
          }
        )

        (var-set next-clearance-id (+ clearance-id u1))
        (ok clearance-id)
      )
    )
  )
)

(define-public (approve-launch-clearance (clearance-id uint))
  (let ((existing-clearance (unwrap! (map-get? launch-clearances { clearance-id: clearance-id }) ERR-DEBRIS-NOT-FOUND)))
    (begin
      (asserts! (has-launch-authority tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get clearance-status existing-clearance) "pending") ERR-INSUFFICIENT-DATA)
      (asserts! (get trajectory-safe existing-clearance) ERR-LAUNCH-CONFLICT)

      (map-set launch-clearances
        { clearance-id: clearance-id }
        {
          satellite-id: (get satellite-id existing-clearance),
          launch-window-start: (get launch-window-start existing-clearance),
          launch-window-end: (get launch-window-end existing-clearance),
          trajectory-safe: (get trajectory-safe existing-clearance),
          requesting-agency: (get requesting-agency existing-clearance),
          clearance-status: "approved",
          approval-time: (some block-height),
          approving-agency: (some tx-sender),
          safety-conditions: (get safety-conditions existing-clearance),
          risk-assessment: (get risk-assessment existing-clearance),
          created-time: (get created-time existing-clearance)
        }
      )
      (ok true)
    )
  )
)

(define-public (reject-launch-clearance (clearance-id uint) (reason (string-ascii 100)))
  (let ((existing-clearance (unwrap! (map-get? launch-clearances { clearance-id: clearance-id }) ERR-DEBRIS-NOT-FOUND)))
    (begin
      (asserts! (has-launch-authority tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get clearance-status existing-clearance) "pending") ERR-INSUFFICIENT-DATA)

      (map-set launch-clearances
        { clearance-id: clearance-id }
        {
          satellite-id: (get satellite-id existing-clearance),
          launch-window-start: (get launch-window-start existing-clearance),
          launch-window-end: (get launch-window-end existing-clearance),
          trajectory-safe: (get trajectory-safe existing-clearance),
          requesting-agency: (get requesting-agency existing-clearance),
          clearance-status: "rejected",
          approval-time: (some block-height),
          approving-agency: (some tx-sender),
          safety-conditions: reason,
          risk-assessment: (get risk-assessment existing-clearance),
          created-time: (get created-time existing-clearance)
        }
      )
      (ok true)
    )
  )
)

(define-public (create-exclusion-zone
  (center-x int) (center-y int) (center-z int) (radius uint)
  (zone-type (string-ascii 30)) (active-until uint) (reason (string-ascii 100)))
  (let ((zone-id (var-get next-clearance-id)))
    (begin
      (asserts! (has-launch-authority tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (> radius u0) ERR-INSUFFICIENT-DATA)
      (asserts! (> active-until block-height) ERR-INVALID-TIMEFRAME)

      (map-set exclusion-zones
        { zone-id: zone-id }
        {
          center-x: center-x,
          center-y: center-y,
          center-z: center-z,
          radius: radius,
          zone-type: zone-type,
          active-until: active-until,
          created-by: tx-sender,
          reason: reason
        }
      )

      (var-set next-clearance-id (+ zone-id u1))
      (ok zone-id)
    )
  )
)

;; Helper Functions
(define-private (assess-trajectory-safety (satellite-id uint) (window-start uint) (window-end uint))
  (let ((trajectory (unwrap-panic (map-get? satellite-trajectories { satellite-id: satellite-id }))))
    {
      safe: true,
      conditions: "Standard safety protocols apply",
      assessment: "Low risk trajectory approved"
    }
  )
)

(define-private (calculate-flight-time (x1 int) (y1 int) (z1 int) (x2 int) (y2 int) (z2 int) (velocity uint))
  (let ((dx (- x2 x1))
        (dy (- y2 y1))
        (dz (- z2 z1)))
    (let ((distance-squared (to-uint (+ (+ (* dx dx) (* dy dy)) (* dz dz)))))
      (if (> velocity u0)
        (/ distance-squared velocity)
        u0
      )
    )
  )
)

(define-private (check-exclusion-zone-conflict (x int) (y int) (z int) (zone-id uint))
  (match (map-get? exclusion-zones { zone-id: zone-id })
    zone (let ((dx (- x (get center-x zone)))
               (dy (- y (get center-y zone)))
               (dz (- z (get center-z zone))))
           (let ((distance-squared (to-uint (+ (+ (* dx dx) (* dy dy)) (* dz dz))))
                 (radius-squared (* (get radius zone) (get radius zone))))
             (and (<= distance-squared radius-squared) (> (get active-until zone) block-height))
           )
         )
    false
  )
)

(define-read-only (validate-launch-window (clearance-id uint))
  (match (map-get? launch-clearances { clearance-id: clearance-id })
    clearance (and
                (is-eq (get clearance-status clearance) "approved")
                (>= block-height (get launch-window-start clearance))
                (<= block-height (get launch-window-end clearance)))
    false
  )
)

;; Initialize contract
(begin
  (map-set authorized-agencies { agency: CONTRACT-OWNER } { authorized: true, launch-authority: true })
)
