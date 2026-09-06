require ["fileinto", "mailbox"];

if anyof (
  header :contains "From" "MAILER-DAEMON",
  header :contains "From" "Mail Delivery Subsystem",
  header :contains "From" "postmaster",
  header :contains "From" "Microsoft Outlook",
  header :contains "Subject" "Undelivered",
  header :contains "Subject" "Undeliverable",
  header :contains "Subject" "Delivery Status Notification",
  header :contains "Subject" "Returned mail:",
  header :contains "Subject" "Mail delivery failed",
  header :contains "Subject" "Quarantined"
) {
  fileinto :create "Mail Delivery System";
  stop;
}
