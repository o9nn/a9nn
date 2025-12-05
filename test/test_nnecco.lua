------------------------------------------------------------------------
-- NNECCO-A9NN Test Suite
-- Tests for Neural Network Embodied Cognitive Coprocessor Orchestrator
-- 22 test cases covering all 5 modules
------------------------------------------------------------------------

require 'torch'
require 'nn'

local mytester = torch.Tester()
local nneccoTest = torch.TestSuite()

------------------------------------------------------------------------
-- EchoReservoirProcessor Tests
------------------------------------------------------------------------

function nneccoTest.EchoReservoirProcessor_creation()
   local esrp = nn.EchoReservoirProcessor()
   mytester:assert(esrp ~= nil, 'EchoReservoirProcessor should be created')
   mytester:asserteq(esrp.reservoirSize, 847, 'Default reservoir size should be 847')
   mytester:asserteq(esrp.inputDim, 768, 'Default input dim should be 768')
   mytester:asserteq(esrp.outputDim, 256, 'Default output dim should be 256')
end

function nneccoTest.EchoReservoirProcessor_custom_config()
   local esrp = nn.EchoReservoirProcessor({
      reservoirSize = 500,
      inputDim = 512,
      outputDim = 128,
      spectralRadius = 0.95
   })
   mytester:asserteq(esrp.reservoirSize, 500, 'Custom reservoir size should be set')
   mytester:asserteq(esrp.spectralRadius, 0.95, 'Custom spectral radius should be set')
end

function nneccoTest.EchoReservoirProcessor_forward()
   local esrp = nn.EchoReservoirProcessor({
      reservoirSize = 100,
      inputDim = 50,
      outputDim = 25
   })
   local input = torch.randn(50)
   local output = esrp:updateOutput(input)
   mytester:assert(output ~= nil, 'Output should be generated')
   mytester:asserteq(output:size(1), 25, 'Output dimension should match')
end

function nneccoTest.EchoReservoirProcessor_adaptParameters()
   local esrp = nn.EchoReservoirProcessor()
   esrp:adaptParameters(0.8, 'chaos')
   mytester:asserteq(esrp.spectralRadius, 0.95, 'Chaos frame should set spectral radius to 0.95')
   esrp:adaptParameters(0.5, 'strategy')
   mytester:asserteq(esrp.spectralRadius, 0.85, 'Strategy frame should set spectral radius to 0.85')
end

function nneccoTest.EchoReservoirProcessor_reset()
   local esrp = nn.EchoReservoirProcessor()
   local input = torch.randn(768)
   esrp:updateOutput(input)
   mytester:assert(esrp.state:norm() > 0, 'State should be non-zero after forward')
   esrp:reset()
   mytester:asserteq(esrp.state:norm(), 0, 'State should be zero after reset')
end

------------------------------------------------------------------------
-- ConsciousnessLayerProcessor Tests
------------------------------------------------------------------------

function nneccoTest.ConsciousnessLayerProcessor_creation()
   local clp = nn.ConsciousnessLayerProcessor()
   mytester:assert(clp ~= nil, 'ConsciousnessLayerProcessor should be created')
   mytester:asserteq(clp.currentLayer.level, 1, 'Default layer should be L1')
   mytester:asserteq(clp.currentLayer.type, 'frame_aware', 'Default layer type should be frame_aware')
end

function nneccoTest.ConsciousnessLayerProcessor_processFrame()
   local clp = nn.ConsciousnessLayerProcessor()
   local result = clp:processFrame('chaos', 'test input', torch.randn(256))
   mytester:assert(result ~= nil, 'Result should be generated')
   mytester:asserteq(clp.currentFrame, 'chaos', 'Current frame should be set')
end

function nneccoTest.ConsciousnessLayerProcessor_layerTransition()
   local clp = nn.ConsciousnessLayerProcessor()
   clp:processFrame('chaos', 'test', nil)
   mytester:asserteq(clp.currentLayer.level, 1, 'Chaos frame should be L1')
   clp:processFrame('strategy', 'test', nil)
   mytester:asserteq(clp.currentLayer.level, 2, 'Strategy frame should be L2')
   mytester:assert(#clp.transitionHistory > 0, 'Transition should be recorded')
end

function nneccoTest.ConsciousnessLayerProcessor_messages()
   local clp = nn.ConsciousnessLayerProcessor()
   clp:processFrame('strategy', 'test', nil)  -- Transition from L1 to L2
   local msg = clp:getMessage()
   mytester:assert(msg ~= nil, 'Message should be available')
   mytester:asserteq(msg.type, 'consciousness_shift', 'Message type should be consciousness_shift')
end

------------------------------------------------------------------------
-- EmotionProcessingUnit Tests
------------------------------------------------------------------------

function nneccoTest.EmotionProcessingUnit_creation()
   local epu = nn.EmotionProcessingUnit()
   mytester:assert(epu ~= nil, 'EmotionProcessingUnit should be created')
   mytester:asserteq(epu.currentEmotion, 'neutral', 'Default emotion should be neutral')
   mytester:asserteq(epu.valence, 0.0, 'Default valence should be 0')
end

function nneccoTest.EmotionProcessingUnit_setEmotion()
   local epu = nn.EmotionProcessingUnit()
   epu:setEmotion('excited', 0.9, 0.8)
   mytester:asserteq(epu.currentEmotion, 'excited', 'Emotion should be set')
   mytester:asserteq(epu.arousal, 0.9, 'Arousal should be set')
   mytester:asserteq(epu.valence, 0.8, 'Valence should be set')
end

function nneccoTest.EmotionProcessingUnit_emotionVector()
   local epu = nn.EmotionProcessingUnit()
   epu:setEmotion('happy', 0.7)
   local vec = epu:getEmotionTensor()
   mytester:assert(vec ~= nil, 'Emotion vector should be returned')
   mytester:asserteq(vec:size(1), 10, 'Emotion vector should have 10 dimensions')
end

function nneccoTest.EmotionProcessingUnit_modulateReservoir()
   local epu = nn.EmotionProcessingUnit()
   epu:setEmotion('excited', 0.8)
   local modulation = epu:modulateReservoir()
   mytester:assert(modulation.input_scale_modifier > 1.0, 'High arousal should increase input scale')
   mytester:assert(modulation.exploration_bonus > 0, 'Arousal should provide exploration bonus')
end

function nneccoTest.EmotionProcessingUnit_history()
   local epu = nn.EmotionProcessingUnit()
   epu:setEmotion('happy', 0.6)
   epu:setEmotion('excited', 0.8)
   local history = epu:getHistory()
   mytester:asserteq(#history, 2, 'History should contain 2 entries')
   mytester:asserteq(history[1].emotion, 'happy', 'First emotion should be happy')
   mytester:asserteq(history[2].emotion, 'excited', 'Second emotion should be excited')
end

------------------------------------------------------------------------
-- LLaMAOrchestrator Tests
------------------------------------------------------------------------

function nneccoTest.LLaMAOrchestrator_creation()
   local orch = nn.LLaMAOrchestrator({numInstances = 3})
   mytester:assert(orch ~= nil, 'LLaMAOrchestrator should be created')
   mytester:asserteq(orch.numInstances, 3, 'Number of instances should be set')
   mytester:asserteq(orch.initialized, false, 'Should not be initialized yet')
end

function nneccoTest.LLaMAOrchestrator_initialize()
   local orch = nn.LLaMAOrchestrator({numInstances = 2})
   orch:initialize()
   mytester:asserteq(orch.initialized, true, 'Should be initialized')
   mytester:asserteq(#orch.instances, 2, 'Should have 2 instances')
   orch:shutdown()
end

function nneccoTest.LLaMAOrchestrator_generate()
   local orch = nn.LLaMAOrchestrator({numInstances = 2})
   orch:initialize()
   local result = orch:generate("Test prompt", {temperature = 0.7})
   mytester:assert(result ~= nil, 'Result should be returned')
   mytester:assert(result.response ~= nil, 'Response should be present')
   mytester:assertgt(orch.stats.totalRequests, 0, 'Should track requests')
   orch:shutdown()
end

function nneccoTest.LLaMAOrchestrator_loadBalancing()
   local orch = nn.LLaMAOrchestrator({numInstances = 3})
   orch:initialize()
   
   -- Generate multiple requests
   for i = 1, 5 do
      orch:generate("Test " .. i)
   end
   
   local status = orch:getStatus()
   mytester:asserteq(#status.instances, 3, 'Should have 3 instances')
   mytester:asserteq(status.completedCount, 5, 'Should have completed 5 tasks')
   orch:shutdown()
end

function nneccoTest.LLaMAOrchestrator_bounds()
   local orch1 = nn.LLaMAOrchestrator({numInstances = 0})
   mytester:asserteq(orch1.numInstances, 1, 'Minimum should be 1 instance')
   
   local orch2 = nn.LLaMAOrchestrator({numInstances = 15})
   mytester:asserteq(orch2.numInstances, 9, 'Maximum should be 9 instances')
end

------------------------------------------------------------------------
-- NNECCOAgent Tests
------------------------------------------------------------------------

function nneccoTest.NNECCOAgent_creation()
   local agent = nn.NNECCOAgent({llamaInstances = 2})
   mytester:assert(agent ~= nil, 'NNECCOAgent should be created')
   mytester:assert(agent.reservoir ~= nil, 'Should have reservoir')
   mytester:assert(agent.consciousness ~= nil, 'Should have consciousness processor')
   mytester:assert(agent.emotionUnit ~= nil, 'Should have emotion unit')
   mytester:assert(agent.llamaOrchestrator ~= nil, 'Should have LLaMA orchestrator')
   agent:shutdown()
end

function nneccoTest.NNECCOAgent_echobeats()
   local agent = nn.NNECCOAgent({llamaInstances = 1})
   local initialPhase = agent.echobeatsPhase
   agent:echobeat()
   mytester:asserteq(agent.echobeatsPhase, initialPhase + 1, 'Phase should advance')
   mytester:assertgt(agent.registers.CYCLE_COUNT, 0, 'Cycle count should increment')
   agent:shutdown()
end

function nneccoTest.NNECCOAgent_process()
   local agent = nn.NNECCOAgent({llamaInstances = 1})
   local result = agent:process('Test input')
   mytester:assert(result ~= nil, 'Result should be returned')
   mytester:assert(result.nnecco ~= nil, 'Should have NNECCO metadata')
   mytester:assert(result.nnecco.reservoirSize > 0, 'Should report reservoir size')
   mytester:assert(result.nnecco.llamaStatus ~= nil, 'Should report LLaMA status')
   agent:shutdown()
end

function nneccoTest.NNECCOAgent_hardwareStatus()
   local agent = nn.NNECCOAgent({llamaInstances = 2})
   local status = agent:getHardwareStatus()
   mytester:assert(status.reservoir ~= nil, 'Should report reservoir status')
   mytester:assert(status.consciousness ~= nil, 'Should report consciousness status')
   mytester:assert(status.emotion ~= nil, 'Should report emotion status')
   mytester:assert(status.llama ~= nil, 'Should report LLaMA status')
   mytester:asserteq(#status.llama.instances, 2, 'Should have 2 LLaMA instances')
   agent:shutdown()
end

function nneccoTest.NNECCOAgent_full_cycle()
   local agent = nn.NNECCOAgent({llamaInstances = 1, reservoirSize = 100})
   
   -- Process input
   agent:process('Test cognitive processing')
   
   -- Run full EchoBeats cycle
   for i = 1, 12 do
      agent:echobeat()
   end
   
   mytester:asserteq(agent.echobeatsPhase, 1, 'Should wrap back to phase 1')
   mytester:asserteq(agent.registers.CYCLE_COUNT, 12, 'Should have 12 cycles')
   
   agent:shutdown()
end

------------------------------------------------------------------------
-- Run Tests
------------------------------------------------------------------------

mytester:add(nneccoTest)
mytester:run()
