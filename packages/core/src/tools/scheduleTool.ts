/**
 * @license
 * Copyright 2025 Qwen
 * SPDX-License-Identifier: Apache-2.0
 */

import { BaseDeclarativeTool, BaseToolInvocation, Kind } from './tools.js';
import { ToolNames, ToolDisplayNames } from './tool-names.js';
import type { ToolResult } from './tools.js';
import type { Config } from '../config/config.js';
import type { ScheduledTask } from '../services/schedulerService.js';

export interface ScheduleToolParams {
  action: 'add' | 'remove' | 'list' | 'enable' | 'disable' | 'update';
  task_id?: string;
  name?: string;
  description?: string;
  cron_expression?: string;
  command?: string;
  prompt?: string;
  task_type?: 'shell' | 'qwen';
  max_runs?: number;
}

class ScheduleToolInvocation extends BaseToolInvocation<
  ScheduleToolParams,
  ToolResult
> {
  constructor(
    private readonly config: Config,
    params: ScheduleToolParams,
  ) {
    super(params);
  }

  getDescription(): string {
    return `Schedule action: ${this.params.action}`;
  }

  async execute(_signal: AbortSignal): Promise<ToolResult> {
    const { action } = this.params;
    const scheduler = this.config.getSchedulerService();

    if (!scheduler) {
      return {
        llmContent: 'Scheduler service not available',
        returnDisplay: '❌ Scheduler service not available',
      };
    }

    let resultText = '';

    switch (action) {
      case 'add':
        resultText = this.handleAdd(scheduler);
        break;
      case 'remove':
        resultText = this.handleRemove(scheduler);
        break;
      case 'list':
        resultText = this.handleList(scheduler);
        break;
      case 'enable':
        resultText = this.handleEnable(scheduler);
        break;
      case 'disable':
        resultText = this.handleDisable(scheduler);
        break;
      case 'update':
        resultText = this.handleUpdate(scheduler);
        break;
      default:
        resultText = `❌ Unknown action: ${action}`;
    }

    return {
      llmContent: resultText,
      returnDisplay: resultText,
    };
  }

  private handleAdd(scheduler: any): string {
    if (!this.params.name) {
      return '❌ Task name is required for add action.';
    }

    if (!this.params.cron_expression) {
      return '❌ Cron expression is required for add action.';
    }

    if (!this.params.command && !this.params.prompt) {
      return '❌ Either command or prompt is required for add action.';
    }

    const task = scheduler.addTask({
      name: this.params.name,
      description: this.params.description || '',
      cronExpression: this.params.cron_expression,
      command: this.params.command,
      prompt: this.params.prompt,
      taskType: this.params.task_type || (this.params.command ? 'shell' : 'qwen'),
      maxRuns: this.params.max_runs,
    });

    return `✅ Scheduled task added successfully!\n\n` +
           `**Task ID**: \`${task.id}\`\n` +
           `**Name**: ${task.name}\n` +
           `**Description**: ${task.description || 'No description'}\n` +
           `**Schedule**: ${task.cronExpression}\n` +
           `**Command**: \`${task.command || 'N/A'}\`\n` +
           `**Prompt**: ${task.prompt || 'N/A'}\n` +
           `**Type**: ${task.taskType}\n` +
           `**Max Runs**: ${task.maxRuns || 'Unlimited'}\n` +
           `**Status**: Enabled`;
  }

  private handleRemove(scheduler: any): string {
    const task = scheduler.getTask(this.params.task_id!);

    if (!task) {
      return `❌ Task with ID "${this.params.task_id}" not found.`;
    }

    scheduler.removeTask(this.params.task_id!);

    return `✅ Scheduled task removed successfully!\n\n` +
           `**Task ID**: ${this.params.task_id}\n` +
           `**Name**: ${task.name}`;
  }

  private handleList(scheduler: any): string {
    const tasks = scheduler.getAllTasks();

    if (tasks.length === 0) {
      return '📋 No scheduled tasks found.';
    }

    let output = `📋 Scheduled Tasks (${tasks.length}):\n\n`;

    tasks.forEach((task: ScheduledTask, index: number) => {
      output += `${index + 1}. **${task.name}**\n`;
      output += `   - ID: \`${task.id}\`\n`;
      output += `   - Description: ${task.description || 'No description'}\n`;
      output += `   - Schedule: ${task.cronExpression}\n`;
      output += `   - Type: ${task.taskType}\n`;
      output += `   - Status: ${task.enabled ? '✅ Enabled' : '❌ Disabled'}\n`;
      output += `   - Run Count: ${task.runCount}\n`;
      if (task.lastRun) {
        output += `   - Last Run: ${new Date(task.lastRun).toLocaleString()}\n`;
      }
      if (task.nextRun) {
        output += `   - Next Run: ${new Date(task.nextRun).toLocaleString()}\n`;
      }
      output += '\n';
    });

    return output;
  }

  private handleEnable(scheduler: any): string {
    const success = scheduler.enableTask(this.params.task_id!);

    if (!success) {
      return `❌ Task with ID "${this.params.task_id}" not found.`;
    }

    return `✅ Scheduled task enabled successfully!\n\n` +
           `**Task ID**: ${this.params.task_id}`;
  }

  private handleDisable(scheduler: any): string {
    const success = scheduler.disableTask(this.params.task_id!);

    if (!success) {
      return `❌ Task with ID "${this.params.task_id}" not found.`;
    }

    return `✅ Scheduled task disabled successfully!\n\n` +
           `**Task ID**: ${this.params.task_id}`;
  }

  private handleUpdate(scheduler: any): string {
    const task = scheduler.getTask(this.params.task_id!);

    if (!task) {
      return `❌ Task with ID "${this.params.task_id}" not found.`;
    }

    const updatedTask = scheduler.updateTask(this.params.task_id!, {
      name: this.params.name,
      description: this.params.description,
      cronExpression: this.params.cron_expression,
      command: this.params.command,
      prompt: this.params.prompt,
      taskType: this.params.task_type,
    });

    if (!updatedTask) {
      return `❌ Failed to update task.`;
    }

    return `✅ Scheduled task updated successfully!\n\n` +
           `**Task ID**: ${this.params.task_id}\n` +
           `**Name**: ${updatedTask.name}\n` +
           `**Schedule**: ${updatedTask.cronExpression}\n` +
           `**Status**: ${updatedTask.enabled ? '✅ Enabled' : '❌ Disabled'}`;
  }
}

/**
 * Schedule tool for managing timed/scheduled tasks
 */
export class ScheduleTool extends BaseDeclarativeTool<ScheduleToolParams, ToolResult> {
  static readonly Name: string = ToolNames.SCHEDULE;

  constructor(private readonly config: Config) {
    const schema = {
      type: 'object',
      properties: {
        action: {
          type: 'string',
          enum: ['add', 'remove', 'list', 'enable', 'disable', 'update'],
        },
        task_id: {
          type: 'string',
        },
        name: {
          type: 'string',
        },
        description: {
          type: 'string',
        },
        cron_expression: {
          type: 'string',
        },
        command: {
          type: 'string',
        },
        prompt: {
          type: 'string',
        },
        task_type: {
          type: 'string',
          enum: ['shell', 'qwen'],
        },
        max_runs: {
          type: 'number',
        },
      },
      required: ['action'],
    };

    super(
      ScheduleTool.Name,
      ToolDisplayNames.SCHEDULE,
      `Manage timed/scheduled tasks that can execute shell commands or trigger Qwen AI responses.

Available actions:
- add: Create a new scheduled task
- remove: Delete a task by ID
- list: List all scheduled tasks
- enable: Enable a disabled task
- disable: Disable a task
- update: Update task parameters

Parameters:
- cron_expression: Time expression (e.g., "30s", "1m", "*/5m", "0 * * * *")
- max_runs: Maximum number of executions (optional, unlimited if not specified)
- task_type: "shell" for commands, "qwen" for AI responses`,
      Kind.Other,
      schema,
    );
  }

  protected createInvocation(params: ScheduleToolParams) {
    return new ScheduleToolInvocation(this.config, params);
  }
}
