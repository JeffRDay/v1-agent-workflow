# v1-agent-workflow

Experimentation with agentic development and agent orchestration while continuing
alignment with Continuous Delivery. 

## What Went Well

- Utilizing multiple agent personas to generate a spec w/ tasks
- Using scripts to control context windows and agent personas
- Pipelines w/ applicable code scans, unit tests, and scenario tests is just as important, if not more so, than trad dev workflows. 
- Keeping specs as files that are iterated upon as the source of truth for a feature
- First prompt resulting in a hello world production deployment is critical to establishing flow. 

## What Went Wrong

- Tasks should probably be independently deployable or large changes build up locally. 
- Messed around with baking in telemetry. It was terrible. Need to re-think architecutre from day 0. Need to rethink "measuring success" across agent personas. 

## What is Next

- Re-work workflow and agent personas for de-composing a spec into "small", independently deployable changes. 
- Re-work personas and architecture approach for user journey & telemtry metrics measuring frequency of feature use. 

## Repo Structure

- agents/: Agent role definitions (PM, Architect, Designer, Coder, Inspector) that drive the workflow.
- docs/: Process documentation for the agentic development flow.
- scripts/: Shell scripts that orchestrate spec enrichment (`feat.sh`) and implementation/test review (`impl.sh`).
