import React from 'react';
import { ChakraProvider, Box, Text } from '@chakra-ui/react';
import ReactFlow, { MiniMap, Controls, Background } from 'reactflow';
import 'reactflow/dist/style.css';

function App() {
  const nodes = [];
  const edges = [];

  return (
    <ChakraProvider>
      <Box p={4}>
        <Text fontSize="2xl" mb={4}>
          Welcome to Tactu with Chakra UI and React Flow
        </Text>
        <Box height="500px" border="1px solid #ddd">
          <ReactFlow nodes={nodes} edges={edges}>
            <MiniMap />
            <Controls />
            <Background />
          </ReactFlow>
        </Box>
      </Box>
    </ChakraProvider>
  );
}

export default App;
