------------------------------------------------------------------------
-- Inferno Kernel AGI Operating System Test Suite
-- Tests for kernel-based cognitive operating system
------------------------------------------------------------------------

require 'torch'
require 'nn'

local mytester = torch.Tester()
local infernoTest = torch.TestSuite()

------------------------------------------------------------------------
-- InfernoKernel Tests
------------------------------------------------------------------------

function infernoTest.InfernoKernel_boot()
   local kernel = nn.InfernoKernel()
   mytester:assert(kernel ~= nil, 'Kernel should be created')
   mytester:assert(kernel.version ~= nil, 'Kernel should have version')
   mytester:assert(kernel.bootTime > 0, 'Kernel should have boot time')
   mytester:assertgt(kernel:countSyscalls(), 0, 'Kernel should have syscalls')
   mytester:assertgt(kernel:countNamespace(), 0, 'Kernel should have namespace')
end

function infernoTest.InfernoKernel_syscalls()
   local kernel = nn.InfernoKernel()
   
   -- Test syscall table
   mytester:assert(kernel.syscalls.think ~= nil, 'think syscall should exist')
   mytester:assert(kernel.syscalls.reason ~= nil, 'reason syscall should exist')
   mytester:assert(kernel.syscalls.feel ~= nil, 'feel syscall should exist')
   mytester:assert(kernel.syscalls.remember ~= nil, 'remember syscall should exist')
   mytester:assert(kernel.syscalls.spawn_agent ~= nil, 'spawn_agent syscall should exist')
end

function infernoTest.InfernoKernel_spawn_process()
   local kernel = nn.InfernoKernel()
   
   local result = kernel.syscalls.spawn_agent(0, {
      name = "test_agent",
      role = "worker"
   })
   
   mytester:assert(result.success, 'Agent spawn should succeed')
   mytester:assert(result.pid ~= nil, 'PID should be assigned')
   mytester:asserteq(result.process.name, "test_agent", 'Process name should match')
end

function infernoTest.InfernoKernel_think_syscall()
   local kernel = nn.InfernoKernel()
   
   -- Spawn a process first
   local spawnResult = kernel.syscalls.spawn_agent(0, {name = "thinker"})
   local pid = spawnResult.pid
   
   -- Test think syscall
   local thinkResult = kernel.syscalls.think(pid, "What is consciousness?", {})
   
   mytester:assert(thinkResult.success, 'Think syscall should succeed')
   mytester:assert(thinkResult.thought_id ~= nil, 'Thought ID should be assigned')
   mytester:asserteq(kernel.stats.thoughtsProcessed, 1, 'Thought count should increment')
end

function infernoTest.InfernoKernel_remember_forget()
   local kernel = nn.InfernoKernel()
   
   local spawnResult = kernel.syscalls.spawn_agent(0, {name = "memory_test"})
   local pid = spawnResult.pid
   
   -- Remember something
   local rememberResult = kernel.syscalls.remember(pid, "favorite_color", "blue", 0.8)
   mytester:assert(rememberResult.success, 'Remember should succeed')
   
   -- Forget with high threshold (should not forget)
   local forgetResult = kernel.syscalls.forget(pid, "favorite_color", 0.9)
   mytester:assert(forgetResult.success, 'Forget call should succeed')
   mytester:asserteq(forgetResult.forgotten, false, 'Should not forget (attention too high)')
end

function infernoTest.InfernoKernel_ipc()
   local kernel = nn.InfernoKernel()
   
   -- Spawn two processes
   local proc1 = kernel.syscalls.spawn_agent(0, {name = "sender"})
   local proc2 = kernel.syscalls.spawn_agent(0, {name = "receiver"})
   
   -- Send thought
   local sendResult = kernel.syscalls.send_thought(proc1.pid, proc2.pid, "Hello!")
   mytester:assert(sendResult.success, 'Send should succeed')
   
   -- Receive thought
   local receiveResult = kernel.syscalls.receive_thought(proc2.pid, false)
   mytester:assert(receiveResult.success, 'Receive should succeed')
   mytester:assert(receiveResult.message ~= nil, 'Message should be received')
   mytester:asserteq(receiveResult.message.from, proc1.pid, 'Sender PID should match')
end

function infernoTest.InfernoKernel_namespace()
   local kernel = nn.InfernoKernel()
   
   -- Test namespace access
   local proc = kernel:open('/proc')
   mytester:assert(proc ~= nil, 'Should open /proc')
   
   local atomspace = kernel:open('/atomspace')
   mytester:assert(atomspace ~= nil, 'Should open /atomspace')
   
   local agents = kernel:open('/agents')
   mytester:assert(agents ~= nil, 'Should open /agents')
end

function infernoTest.InfernoKernel_ps()
   local kernel = nn.InfernoKernel()
   
   -- Spawn some processes
   kernel.syscalls.spawn_agent(0, {name = "agent1"})
   kernel.syscalls.spawn_agent(0, {name = "agent2"})
   
   local processes = kernel:ps()
   mytester:assertge(#processes, 2, 'Should have at least 2 processes')
end

function infernoTest.InfernoKernel_kill()
   local kernel = nn.InfernoKernel()
   
   local spawnResult = kernel.syscalls.spawn_agent(0, {name = "killme"})
   local pid = spawnResult.pid
   
   mytester:assert(kernel:getProcess(pid) ~= nil, 'Process should exist')
   
   local killed = kernel:kill(pid)
   mytester:assert(killed, 'Kill should succeed')
   mytester:assert(kernel:getProcess(pid) == nil, 'Process should be removed')
end

------------------------------------------------------------------------
-- CognitiveProcess Tests
------------------------------------------------------------------------

function infernoTest.CognitiveProcess_creation()
   local kernel = nn.InfernoKernel()
   
   local process = nn.CognitiveProcess(kernel, {
      pid = 100,
      name = "test_process",
      role = "thinker"
   })
   
   mytester:assert(process ~= nil, 'Process should be created')
   mytester:asserteq(process.pid, 100, 'PID should match')
   mytester:asserteq(process.name, "test_process", 'Name should match')
   mytester:asserteq(process.state, "ready", 'Initial state should be ready')
end

function infernoTest.CognitiveProcess_emotion()
   local kernel = nn.InfernoKernel()
   local process = nn.CognitiveProcess(kernel, {pid = 101})
   
   process:feel("joy", 0.8)
   
   mytester:asserteq(process.emotion.type, "joy", 'Emotion type should be set')
   mytester:asserteq(process.emotion.intensity, 0.8, 'Emotion intensity should be set')
end

function infernoTest.CognitiveProcess_syscall()
   local kernel = nn.InfernoKernel()
   
   -- Need to register process in kernel first
   local spawnResult = kernel.syscalls.spawn_agent(0, {name = "syscaller"})
   local process = nn.CognitiveProcess(kernel, {
      pid = spawnResult.pid,
      name = "syscaller"
   })
   kernel.processTable[process.pid] = process
   
   -- Make syscall
   local result = process:think("test thought", {})
   mytester:assert(result.success, 'Syscall should succeed')
end

function infernoTest.CognitiveProcess_working_memory()
   local kernel = nn.InfernoKernel()
   local process = nn.CognitiveProcess(kernel, {pid = 102})
   
   -- Add to working memory
   table.insert(process.workingMemory, {
      type = "fact",
      content = "The sky is blue",
      timestamp = os.time()
   })
   
   mytester:asserteq(#process.workingMemory, 1, 'Working memory should have 1 item')
end

------------------------------------------------------------------------
-- DistributedAtomSpace Tests
------------------------------------------------------------------------

function infernoTest.DistributedAtomSpace_creation()
   local das = nn.DistributedAtomSpace({
      nodeId = 1,
      clusterNodes = {[2] = {host = "localhost", port = 8081}}
   })
   
   mytester:assert(das ~= nil, 'DistributedAtomSpace should be created')
   mytester:asserteq(das.nodeId, 1, 'Node ID should be set')
   mytester:asserteq(das:getNodeCount(), 2, 'Should have 2 nodes (self + 1 remote)')
end

function infernoTest.DistributedAtomSpace_versioning()
   local das = nn.DistributedAtomSpace({nodeId = 1})
   
   local node = das:addNode("ConceptNode", "test_node", {0.8, 0.9})
   
   mytester:assert(das.versionVectors[node.uuid] ~= nil, 'Version vector should exist')
   mytester:assert(das.versionVectors[node.uuid][1] ~= nil, 'Version for node 1 should exist')
   mytester:assertge(das.versionVectors[node.uuid][1], 1, 'Version should be >= 1')
end

function infernoTest.DistributedAtomSpace_sync()
   local das = nn.DistributedAtomSpace({
      nodeId = 1,
      syncInterval = 0  -- Allow immediate sync
   })
   
   -- Add some nodes
   das:addNode("ConceptNode", "node1", {0.9, 0.9})
   das:addNode("ConceptNode", "node2", {0.8, 0.8})
   
   local syncResult = das:sync()
   mytester:assert(syncResult.success, 'Sync should succeed')
   mytester:asserteq(#das.pendingOps, 0, 'Pending ops should be cleared after sync')
end

function infernoTest.DistributedAtomSpace_cluster_status()
   local das = nn.DistributedAtomSpace({
      nodeId = 1,
      clusterNodes = {
         [2] = {host = "host2", port = 8081},
         [3] = {host = "host3", port = 8082}
      }
   })
   
   local status = das:getClusterStatus()
   mytester:asserteq(status.nodeId, 1, 'Node ID should match')
   mytester:asserteq(status.totalNodes, 3, 'Should have 3 total nodes')
end

------------------------------------------------------------------------
-- CognitiveScheduler Tests
------------------------------------------------------------------------

function infernoTest.CognitiveScheduler_creation()
   local kernel = nn.InfernoKernel()
   local scheduler = nn.CognitiveScheduler(kernel, {
      policy = "consciousness_aware"
   })
   
   mytester:assert(scheduler ~= nil, 'Scheduler should be created')
   mytester:asserteq(scheduler.policy, "consciousness_aware", 'Policy should be set')
end

function infernoTest.CognitiveScheduler_enqueue_dequeue()
   local kernel = nn.InfernoKernel()
   local scheduler = nn.CognitiveScheduler(kernel)
   
   local process1 = nn.CognitiveProcess(kernel, {pid = 201, priority = 5})
   local process2 = nn.CognitiveProcess(kernel, {pid = 202, priority = 3})
   
   scheduler:enqueue(process1)
   scheduler:enqueue(process2)
   
   mytester:asserteq(#scheduler.readyQueue, 2, 'Ready queue should have 2 processes')
   
   local next = scheduler:dequeue()
   mytester:assert(next ~= nil, 'Should dequeue a process')
end

function infernoTest.CognitiveScheduler_consciousness_aware()
   local kernel = nn.InfernoKernel()
   local scheduler = nn.CognitiveScheduler(kernel, {
      policy = "consciousness_aware"
   })
   
   -- Create processes with different consciousness levels
   local p1 = nn.CognitiveProcess(kernel, {pid = 301, consciousnessLevel = 1})
   local p2 = nn.CognitiveProcess(kernel, {pid = 302, consciousnessLevel = 3})
   
   scheduler:enqueue(p1)
   scheduler:enqueue(p2)
   
   -- Higher consciousness should be selected first
   local next = scheduler:dequeue()
   mytester:asserteq(next.consciousnessLevel, 3, 'Higher consciousness should be selected')
end

function infernoTest.CognitiveScheduler_block_unblock()
   local kernel = nn.InfernoKernel()
   local scheduler = nn.CognitiveScheduler(kernel)
   
   local process = nn.CognitiveProcess(kernel, {pid = 401})
   process.state = "running"
   
   scheduler:block(process, "waiting for IO")
   mytester:asserteq(process.state, "blocked", 'Process should be blocked')
   mytester:asserteq(#scheduler.blockedQueue, 1, 'Blocked queue should have 1 process')
   
   scheduler:unblock(process)
   mytester:asserteq(process.state, "ready", 'Process should be ready')
   mytester:asserteq(#scheduler.blockedQueue, 0, 'Blocked queue should be empty')
end

------------------------------------------------------------------------
-- KernelAgent Tests
------------------------------------------------------------------------

function infernoTest.KernelAgent_creation()
   local kernel = nn.InfernoKernel()
   
   local agent = nn.KernelAgent(kernel, {
      name = "TestAgent",
      role = "tester"
   })
   
   mytester:assert(agent ~= nil, 'KernelAgent should be created')
   mytester:assert(agent.pid ~= nil, 'Agent should have PID')
   mytester:assert(agent.process ~= nil, 'Agent should have process')
   mytester:asserteq(agent.name, "TestAgent", 'Agent name should match')
end

function infernoTest.KernelAgent_think()
   local kernel = nn.InfernoKernel()
   local agent = nn.KernelAgent(kernel, {name = "Thinker"})
   
   local result = agent:think("What is the meaning of life?", {})
   mytester:assert(result.success, 'Think should succeed')
   mytester:assert(result.thought_id ~= nil, 'Thought ID should be assigned')
end

function infernoTest.KernelAgent_subordinate()
   local kernel = nn.InfernoKernel()
   local agent = nn.KernelAgent(kernel, {name = "Manager"})
   
   local sub = agent:spawnSubordinate({
      name = "Worker",
      role = "worker"
   })
   
   mytester:assert(sub ~= nil, 'Subordinate should be created')
   mytester:assert(sub.pid ~= nil, 'Subordinate should have PID')
   mytester:asserteq(#agent.subordinates, 1, 'Manager should have 1 subordinate')
end

function infernoTest.KernelAgent_ipc()
   local kernel = nn.InfernoKernel()
   
   local agent1 = nn.KernelAgent(kernel, {name = "Agent1"})
   local agent2 = nn.KernelAgent(kernel, {name = "Agent2"})
   
   -- Send thought
   local sendResult = agent1:sendThought(agent2.pid, "Hello from Agent1")
   mytester:assert(sendResult.success, 'Send should succeed')
   
   -- Receive thought
   local receiveResult = agent2:receiveThought(false)
   mytester:assert(receiveResult.success, 'Receive should succeed')
   mytester:assert(receiveResult.message ~= nil, 'Message should exist')
end

function infernoTest.KernelAgent_consciousness()
   local kernel = nn.InfernoKernel()
   local agent = nn.KernelAgent(kernel, {name = "Conscious"})
   
   local result = agent:shiftConsciousness(2)
   mytester:assert(result.success, 'Consciousness shift should succeed')
   mytester:asserteq(agent.process.consciousnessLevel, 2, 'Consciousness level should be 2')
end

------------------------------------------------------------------------
-- Integration Tests
------------------------------------------------------------------------

function infernoTest.Integration_kernel_agent_lifecycle()
   local kernel = nn.InfernoKernel()
   
   -- Create agent
   local agent = nn.KernelAgent(kernel, {name = "LifecycleTest"})
   local pid = agent.pid
   
   -- Verify registration
   mytester:assert(kernel:getProcess(pid) ~= nil, 'Process should be registered')
   
   -- Agent thinks
   agent:think("Integration test thought", {})
   mytester:assertge(kernel.stats.thoughtsProcessed, 1, 'Thought should be processed')
   
   -- Shutdown agent
   agent:shutdown()
   mytester:assert(kernel:getProcess(pid) == nil, 'Process should be removed after shutdown')
end

function infernoTest.Integration_multi_agent_communication()
   local kernel = nn.InfernoKernel()
   
   -- Create multiple agents
   local agents = {}
   for i = 1, 3 do
      agents[i] = nn.KernelAgent(kernel, {name = "Agent" .. i})
   end
   
   -- Agent 1 sends to all others
   for i = 2, 3 do
      agents[1]:sendThought(agents[i].pid, "Broadcast message")
   end
   
   -- Others receive
   for i = 2, 3 do
      local msg = agents[i]:receiveThought(false)
      mytester:assert(msg.message ~= nil, 'Agent ' .. i .. ' should receive message')
   end
end

function infernoTest.Integration_distributed_knowledge()
   local kernel = nn.InfernoKernel({
      atomSpace = nn.DistributedAtomSpace({nodeId = 1})
   })
   
   local agent = nn.KernelAgent(kernel, {name = "KnowledgeWorker"})
   
   -- Remember something
   agent:remember("fact1", "Knowledge is distributed", 0.9)
   
   -- Query it back
   local queryResult = agent:queryKnowledge({
      type = "ConceptNode",
      name = "fact1"
   })
   
   mytester:assert(queryResult.success, 'Query should succeed')
end

------------------------------------------------------------------------
-- Run Tests
------------------------------------------------------------------------

mytester:add(infernoTest)

-- Run all tests
local args = {...}
if #args == 0 then
   mytester:run()
else
   mytester:run(args)
end

return mytester
