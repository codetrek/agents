---
name: autopilot
description: Enable autonomous delivery for the current session only when the user explicitly activates autopilot. After plan confirmation, implement the agreed task queue, pass required PR checks, address reviews, merge, and continue until the queue is complete.
disable-model-invocation: true
---

# Autopilot

## Activation and authority

Activate only on the user's explicit command, such as `$autopilot` in Codex,
`/autopilot` in Claude Code, or a clear instruction to enable this mode.
Creating, editing, reviewing, or mentioning this skill does not activate it.

Activation is the user's standing authorization, within the confirmed goal,
to edit files, validate, create task branches and worktrees, commit, push work
branches, open and update PRs, request reviews, reply to review threads, repair
CI and review findings, and merge approved PRs. Once the plan is confirmed,
perform these actions without asking for permission at each delivery step.
The user's explicit activation supplies this authorization; the skill file
alone supplies none. Honor narrower session instructions and host permissions.

Keep the mode active for this session, including context compaction and
resumption of the same session. A new session starts inactive. User steering
updates the active work; a status question does not cancel it. Pause on an
explicit pause request, resume on an explicit resume request, and revoke
standing authorization on disable or session end. Cancel task-owned pending
merge actions and wake-ups when paused or disabled; preserve unfinished work.

Activation authorizes delivery of the agreed work, not arbitrary backlog work,
production deployment, destructive data operations, or changes to account,
permission, protection, or approval settings. Obtain a separate instruction
when an action falls outside the confirmed goal and delivery authorization.

## Confirm the plan and queue

Recover the user's goal, prior decisions, acceptance criteria, and remaining
tasks from the conversation and applicable project records. Reuse an already
confirmed plan. When a plan still needs agreement, inspect and discuss first;
begin execution after the user confirms it. Ask material questions together.
Routine implementation choices within that plan are the agent's responsibility.

Establish an ordered queue with a concrete completion condition and scope for
each task. A confirmed goal can authorize deriving its necessary subtasks;
do not require separate approvals for each subtask. Discuss tasks outside that
goal before adding them. Keep deferred improvements separate from the queue.

Preserve a compact session checkpoint in the host's session state or the
project's existing local planning mechanism: active/paused mode, authorization,
confirmed plan and scope, queue, current worktree and branch, PR and head SHA,
validation and review state, blockers, owned resources, and next action. Keep
it current before compaction or a long wait. Restore it and refresh remote
state before resuming mutations. Store project artifacts inside the project.

## Deliver each task

1. **Implement and verify.** Read applicable instructions and existing
   mechanisms. Use one task worktree shared by its agents, preserving unrelated
   work. Implement the complete agreed behavior, synchronize affected documents,
   and run the project's relevant checks and behavioral validation. Use research
   and independent review agents when available and authorized. Reassess the
   design when repeated failures reveal a structural problem.

2. **Publish the focused change.** Commit and push work promptly, following
   repository conventions, then create or update its PR. Keep its scope tied to
   the task. Use the default Git identity and omit AI co-author attribution.
   Integrate necessary mainline updates using the repository's work-branch
   rules. Resolve conflicts in the task worktree and revalidate.

3. **Follow PR CI and review to completion.** Monitor the actual remote PR head,
   checks, review requests, comments, and approval state. Request review through
   the project's existing mechanism. Read failure logs first; each failed check
   at a given commit may be rerun at most twice beyond its initial run, without
   first establishing a transient infrastructure cause. Count retries across
   sessions, restarts, and workflow reruns. If the check still fails after that
   budget, diagnose and repair the cause before further validation. A passing
   retry does not establish the cause; preserve acceptance criteria and required
   checks. A push starts a new delivery iteration: refresh checks and reviews
   for that head.

   Independently assess each finding against the original task scope. Fix
   introduced Critical/Major issues and defects that would make the agreed
   delivery incorrect. Record smaller or unrelated improvements as deferred
   follow-ups using the project's tracking convention. Include fix, defer, and
   reject as review dispositions. Reply in each finding's own thread with the
   change or reason; resolve it after handling, following repository rules.
   Identify the agent in external review replies and use the required language.
   Repeat review and repair until the final round has no new Critical/Major
   findings and the remote review requirements are satisfied.

4. **Merge and confirm.** Immediately before merging, refresh the head SHA,
   required checks, review threads, mergeability, and approvals. Require
   successful required checks, handled blocking threads, and actual reviewer
   approval for the current head. Never infer approval from silence, approve
   your own PR, bypass protections, weaken gates, or use an administrative merge
   override. Merge using the project's permitted linear-history method and
   bind the operation to the verified head when the platform supports it.
   Recheck after a head change or a failed merge precondition. Confirm the
   platform reports the PR merged and record its resulting commit; an accepted
   auto-merge request or merge-queue entry alone is not completion.

   Once the platform confirms the merge, proceed to closure and cleanup without
   waiting for CI triggered on the mainline after merge. Do not add that wait to
   task plans or acceptance criteria on your own. Perform post-merge CI
   verification only when the user explicitly requests it.

5. **Close and advance.** Update the task's tracking record and remove its
   worktree, temporary files, services, and wake-ups after the confirmed merge.
   Check resources left by failed agents as well. Continue immediately with the
   next ready task in the confirmed queue. Finish the current task's delivery
   before starting the next task unless the agreed plan permits parallel tasks.

For tasks without a PR delivery path, use their confirmed acceptance criteria
and verify the actual resulting artifact. Do not invent a PR or approval gate
for local-only work.

## Waiting, intervention, and completion

Before merge, pending PR CI or review is ongoing work. Keep waiting, inspecting
new results, and acting on failures or feedback. Use bounded watch commands or
yielding polls with reasonable intervals. A watch timeout only ends that watch
command. Do not hand back a final answer merely because a PR was opened, its
required checks are running, or a review has been requested. For long runs, use
an available session-scoped wake-up or heartbeat mechanism, normally every
20 minutes, and remove it when work stops. This skill does not create a
background service or change host execution permissions; do not claim monitoring
will continue without a real continuation mechanism.

Continue resolving problems while useful authorized actions remain. Ask for
user input only when a material unresolved decision, missing credential,
external permission, unavailable reviewer, or other demonstrated blocker
prevents further progress. Ordinary waiting alone is not such a blocker.
State the concrete blocker and the minimum needed intervention, preserve the
checkpoint, and distinguish blocked work from completed work. Never ask
whether to continue with already authorized work.

When every queued task meets its completion criteria, report delivered results,
PRs and merge commits, observed validation, and remaining deferred items or
limitations. Remove task-owned monitoring resources. Remain idle with autopilot
enabled for subsequent confirmed work in the same session until the user
disables it or the session ends.
