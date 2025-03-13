import React from 'react';
import { FlatList } from 'react-native';
import TaskItem from './TaskItem';

const TaskList = ({ tasks, onTaskPress, onTaskLongPress }) => {
  const renderItem = ({ item }) => (
    <TaskItem
      task={item}
      onPress={() => onTaskPress(item)}
      onLongPress={() => onTaskLongPress(item)}
    />
  );

  return (
    <FlatList
      data={tasks}
      renderItem={renderItem}
      keyExtractor={item => item.id.toString()}
      initialNumToRender={10}
      maxToRenderPerBatch={5}
      windowSize={10}
      removeClippedSubviews={true}
    />
  );
};

export default React.memo(TaskList);
