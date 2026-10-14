/// The publishable ack packages in the melos workspace, in publish order.
const publishableAckPackages = <String>[
  'ack',
  'ack_generator',
  'ack_firebase_ai',
  'ack_json_schema_builder',
  'ack_mcp_dart',
];

/// First releases for packages added after the original workspace baseline.
/// Earlier versions have no published API to compare against.
const ackPackageFirstReleases = <String, String>{'ack_mcp_dart': '1.3.0'};
