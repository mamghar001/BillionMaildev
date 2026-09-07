require ["fileinto", "mailbox"];

if anyof (
  header :contains "Subject" "Report Domain:",
  header :contains "Subject" "Report-Domain:",
  header :contains "Subject" "DMARC Report",
  header :contains "Subject" "DMARC Aggregate",
  header :contains "Subject" "DMARC Forensic",
  header :contains ["To", "Cc", "Delivered-To", "Envelope-To", "X-Original-To"] "dmarc@",
  header :contains "From" "noreply-dmarc",
  header :contains "From" "dmarc-noreply",
  header :contains "From" "dmarc-report",
  header :contains "From" "dmarcreport",
  header :contains "From" "dmarc_report",
  header :contains "From" "dmarc_reports",
  header :contains "From" "dmarc-feedback",
  header :contains "From" "dmarc-support",
  header :contains "From" "dmarc_support",
  header :contains "Content-Type" "report-type=feedback-report",
  header :contains "Content-Type" "application/dmarc"
) {
  fileinto :create "dmarcReports";
  stop;
}
