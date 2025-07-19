# Decentralized Space Debris Tracking System

A comprehensive blockchain-based system for tracking space debris, predicting collisions, coordinating cleanup missions, ensuring launch safety, and facilitating international data sharing.

## Overview

This system consists of five interconnected Clarity smart contracts that work together to provide a complete space debris management solution:

1. **Orbital Monitoring Contract** (`orbital-monitoring.clar`) - Tracks space junk location and trajectory data
2. **Collision Prediction Contract** (`collision-prediction.clar`) - Calculates potential satellite impact risks
3. **Cleanup Coordination Contract** (`cleanup-coordination.clar`) - Manages debris removal mission planning
4. **Launch Safety Contract** (`launch-safety.clar`) - Ensures new satellites avoid existing debris fields
5. **International Reporting Contract** (`international-reporting.clar`) - Shares debris data between space agencies

## Key Features

### Orbital Monitoring
- Track debris objects with unique identifiers
- Store position coordinates (x, y, z) and velocity vectors
- Record object size, mass, and classification
- Timestamp all orbital data updates
- Support for both active tracking and historical data

### Collision Prediction
- Calculate collision probabilities between objects
- Set risk thresholds and alert levels
- Track predicted collision timeframes
- Maintain collision avoidance recommendations
- Generate automated risk assessments

### Cleanup Coordination
- Plan and coordinate debris removal missions
- Track mission status and progress
- Assign cleanup priorities based on risk levels
- Manage mission resources and timelines
- Record successful debris removal operations

### Launch Safety
- Validate launch windows against debris fields
- Check trajectory safety for new satellites
- Provide launch clearance approvals
- Maintain exclusion zones around critical debris
- Generate safety compliance reports

### International Reporting
- Share debris data between space agencies
- Maintain data sharing agreements
- Track data access and usage
- Ensure data integrity and authenticity
- Support multi-agency collaboration

## Data Structures

### Debris Object
- `debris-id`: Unique identifier (uint)
- `position`: 3D coordinates (x, y, z as int)
- `velocity`: 3D velocity vector (vx, vy, vz as int)
- `size`: Object dimensions in meters (uint)
- `mass`: Object mass in kilograms (uint)
- `classification`: Object type (string-ascii 50)
- `last-updated`: Timestamp of last data update (uint)
- `tracking-agency`: Responsible tracking organization (principal)

### Collision Risk
- `risk-id`: Unique risk assessment identifier (uint)
- `object1-id`: First object involved (uint)
- `object2-id`: Second object involved (uint)
- `collision-probability`: Risk percentage (uint 0-100)
- `predicted-time`: Estimated collision timeframe (uint)
- `risk-level`: Categorized risk level (string-ascii 20)
- `mitigation-required`: Whether action is needed (bool)

### Cleanup Mission
- `mission-id`: Unique mission identifier (uint)
- `target-debris-id`: Debris object to be removed (uint)
- `mission-status`: Current status (string-ascii 30)
- `assigned-agency`: Responsible organization (principal)
- `planned-start`: Mission start timestamp (uint)
- `estimated-duration`: Expected mission length (uint)
- `priority-level`: Mission priority (uint 1-10)

### Launch Clearance
- `clearance-id`: Unique clearance identifier (uint)
- `satellite-id`: New satellite identifier (uint)
- `launch-window-start`: Launch window opening (uint)
- `launch-window-end`: Launch window closing (uint)
- `trajectory-safe`: Safety validation result (bool)
- `requesting-agency`: Launch organization (principal)
- `clearance-status`: Approval status (string-ascii 20)

### Agency Report
- `report-id`: Unique report identifier (uint)
- `reporting-agency`: Data source organization (principal)
- `data-type`: Type of shared data (string-ascii 50)
- `data-hash`: Data integrity hash (string-ascii 64)
- `access-level`: Data sharing permissions (string-ascii 20)
- `report-timestamp`: When data was shared (uint)

## Contract Functions

### Read Functions
- `get-debris-info`: Retrieve debris object details
- `get-collision-risk`: Get collision risk assessment
- `get-mission-status`: Check cleanup mission progress
- `get-launch-clearance`: Verify launch approval status
- `get-agency-report`: Access shared agency data
- `list-high-risk-debris`: Get objects with high collision risk
- `list-active-missions`: Get ongoing cleanup operations
- `list-pending-launches`: Get launches awaiting clearance

### Write Functions
- `update-debris-position`: Update object orbital data
- `assess-collision-risk`: Calculate new risk assessment
- `plan-cleanup-mission`: Create debris removal mission
- `request-launch-clearance`: Apply for launch approval
- `submit-agency-report`: Share data with other agencies
- `approve-mission`: Authorize cleanup operation
- `grant-launch-clearance`: Approve satellite launch
- `update-mission-status`: Report mission progress

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Caller lacks required permissions
- `ERR-DEBRIS-NOT-FOUND (u101)`: Debris object doesn't exist
- `ERR-INVALID-COORDINATES (u102)`: Position data out of valid range
- `ERR-INVALID-RISK-LEVEL (u103)`: Risk assessment parameters invalid
- `ERR-MISSION-EXISTS (u104)`: Cleanup mission already planned
- `ERR-LAUNCH-CONFLICT (u105)`: Launch window conflicts with debris
- `ERR-INVALID-AGENCY (u106)`: Agency not registered in system
- `ERR-DATA-INTEGRITY (u107)`: Shared data fails validation
- `ERR-INVALID-TIMEFRAME (u108)`: Timestamp parameters invalid
- `ERR-INSUFFICIENT-DATA (u109)`: Not enough data for calculation

## Usage Examples

### Track New Debris Object
\`\`\`clarity
(update-debris-position u1001 1000 2000 3000 -10 5 -2 u50 u1000 "satellite-fragment" u1640995200)
\`\`\`

### Assess Collision Risk
\`\`\`clarity
(assess-collision-risk u1001 u1002 u75 u1641081600 "high" true)
\`\`\`

### Plan Cleanup Mission
\`\`\`clarity
(plan-cleanup-mission u2001 u1001 "planned" 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u1641168000 u86400 u8)
\`\`\`

### Request Launch Clearance
\`\`\`clarity
(request-launch-clearance u3001 u5001 u1641254400 u1641340800 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
\`\`\`

## Security Considerations

- All write operations require proper authorization
- Data integrity is maintained through validation checks
- Agency permissions are enforced for sensitive operations
- Historical data is immutable once recorded
- Cross-agency data sharing requires explicit approval

## Testing

The system includes comprehensive tests covering:
- Debris tracking and position updates
- Collision risk calculations and assessments
- Mission planning and status management
- Launch safety validations and clearances
- International data sharing workflows
- Error handling and edge cases
- Authorization and permission checks

Run tests with:
\`\`\`bash
npm test
\`\`\`

## Deployment

1. Install dependencies: `npm install`
2. Configure Clarinet: Update `Clarinet.toml` with network settings
3. Deploy contracts: `clarinet deploy`
4. Verify deployment: Run integration tests
5. Initialize system: Set up initial agency registrations

## Contributing

1. Follow Clarity coding standards
2. Add comprehensive tests for new features
3. Update documentation for API changes
4. Ensure all security checks pass
5. Test cross-contract interactions thoroughly

## License

MIT License - See LICENSE file for details
