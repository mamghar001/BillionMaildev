# Alex Hormozi-Style "Value-First" Email Templates

These templates are designed around the value-first philosophy: **Give away the information (case study/system blueprint) for free to build trust, and charge for the complex implementation (infrastructure, custom databases, and maintenance).**

---

## The Conversion Psychology (Hormozi Funnel)
1. **The Hook:** A highly relevant case study showing the exact outcome they want (adding revenue using an AI/infrastructure system).
2. **The "Give" (The Lead Magnet):** Offering the complete, step-by-step SOP/blueprint of *how* we did it, with zero friction, so they can replicate it themselves.
3. **The Call to Action (Testimonial Loop):** Asking only if they want the details for free (optionally in exchange for a testimonial if they find it valuable).
4. **The Monetization:** Once they read the blueprint, they realize setting up GRE tunnels, Postfix routing, and private databases is highly technical. They reply: *"Can you just set this up for us?"*

---

## Vertical 1: Software & SaaS (Targeting ARR/CAC)

```text
Subject: quick query for {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your company{{end}}

Hi {{if .Subscriber.first_name}}{{.Subscriber.first_name}}{{else}}there{{end}},

{I was looking at|Came across|Checking out} {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your company{{end}} in the tech space. I'll get straight to the point:

{We recently helped a B2B software firm add $84,000 in new ARR in just 45 days using a custom AI client acquisition setup.|We just built a private outbound engine for a SaaS company that booked 38 sales meetings in 30 days without spending a dime on ZoomInfo or Apollo fees.}

I put together a {complete step-by-step breakdown|short case study and SOP} showing the exact technical workflow, so you can duplicate it for your business for free. 

{Would you like me to send over the PDF? (All I ask in return is a quick testimonial if you find it valuable).|Should I drop the document here? No sales pitch or strings.|Let me know if you'd like to check it out.}

Best,
Madison
```

---

## Vertical 2: Marketing & Creative Agencies (Targeting Client Acquisition)

```text
Subject: quick check for {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your agency{{end}}

Hi {{if .Subscriber.first_name}}{{.Subscriber.first_name}}{{else}}there{{end}},

{I was reviewing|Came across|Checking out} {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your agency{{end}} in the marketing space. I'll be brief:

{We recently helped a digital agency secure 14 high-ticket retainer clients in 60 days using a new AI-driven outbound system.|We just mapped out an outbound acquisition setup for a marketing firm that added $22,000 in monthly recurring revenue (MRR) without hiring expensive SDR teams.}

I wrote up a {detailed SOP and video breakdown|step-by-step document} showing exactly how the acquisition system was built, so you can duplicate it for your agency for free.

{Would it be alright if I sent the breakdown over? (All I ask is a testimonial if it helps you).|Can I drop the document in this thread?|Let me know if you want me to send it.}

Best,
Madison
```

---

## Vertical 3: Management Consulting & Advisory (Targeting High-Value Deal Flow)

```text
Subject: quick query for {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your firm{{end}}

Hi {{if .Subscriber.first_name}}{{.Subscriber.first_name}}{{else}}there{{end}},

{I was reviewing|Came across|Checking out} {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your firm{{end}} in the advisory space. I'll get straight to the point:

{We recently helped a management consulting firm close $110,000 in new contract value in 30 days using an automated outbound infrastructure.|We just built a partner-led advisory pipeline that generated 9 qualified discovery calls in two weeks with zero database lookup fees.}

I put together a {full blueprint and workflow document|step-by-step case study} showing how we configured this acquisition system, so you can duplicate it for your firm for free.

{Would you like me to send the PDF over? (Just looking for a quick testimonial if you find it useful).|Should I drop the link here?|Let me know if you'd like to check it out.}

Best,
Madison
```
