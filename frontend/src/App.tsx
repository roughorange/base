import { ChakraProvider, Box, Text } from '@chakra-ui/react';
import ReactFlow, { MiniMap, Controls, Background, Node, Edge } from 'reactflow';
import 'reactflow/dist/style.css';

/**
 * The main App component that renders the user interface.
 * This component uses Chakra UI for styling and React Flow for interactive flowcharts.
 * Naming convention: PascalCase for components.
 */
function App() {
  // Define an empty array of nodes with the correct type from React Flow.
  // Naming convention: camelCase for variables.
  const nodes: Node[] = [];

  // Define an empty array of edges with the correct type from React Flow.
  // Naming convention: camelCase for variables.
  const edges: Edge[] = [];

  /**
   * Renders the main UI layout, including a title and the flowchart using React Flow.
   * ChakraProvider is used to apply the Chakra UI theme.
   */
  return (
    <ChakraProvider>
      <Box p={4}>
        {/* Title text for the application */}
        <Text fontSize="2xl" mb={4}>
          Welcome to BASE with Chakra UI and React Flow
        </Text>
        {/* Container for the flowchart with a fixed height and border */}
        <Box height="500px" border="1px solid #ddd">
          {/* React Flow component to display nodes and edges */}
          <ReactFlow nodes={nodes} edges={edges}>
            {/* Additional React Flow components for controls and background */}
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
