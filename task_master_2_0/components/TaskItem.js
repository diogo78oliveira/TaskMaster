import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import FastImage from 'react-native-fast-image'; // Add this package

const TaskItem = ({ task, onPress, onLongPress }) => {
  // ...existing code...
  
  return (
    <TouchableOpacity 
      onPress={onPress} 
      onLongPress={onLongPress}
      // Using useCallback in parent component for these handlers is recommended
    >
      <View>
        {task.imageUrl && (
          <FastImage
            source={{ uri: task.imageUrl }}
            style={styles.taskImage}
            resizeMode={FastImage.resizeMode.cover}
          />
        )}
        <Text>{task.title}</Text>
        {/* ...existing code... */}
      </View>
    </TouchableOpacity>
  );
};

export default React.memo(TaskItem);
