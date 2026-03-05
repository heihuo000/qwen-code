/**
 * @license
 * Copyright 2025 Qwen
 * SPDX-License-Identifier: Apache-2.0
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

export type TaskType = 'shell' | 'qwen';

export interface ScheduledTask {
  id: string;
  name: string;
  description: string;
  cronExpression: string;
  command?: string;
  prompt?: string;
  taskType: TaskType;
  enabled: boolean;
  lastRun?: number;
  nextRun?: number;
  runCount: number;
  maxRuns?: number;
}

export interface ScheduleTaskParams {
  name: string;
  description?: string;
  cronExpression: string;
  command?: string;
  prompt?: string;
  taskType?: TaskType;
  maxRuns?: number;
}

export type QuerySubmitCallback = (query: string) => Promise<void>;

export class SchedulerService {
  private tasks: Map<string, ScheduledTask> = new Map();
  private timers: Map<string, NodeJS.Timeout> = new Map();
  private isRunning: boolean = false;
  private schedulesPath: string | null = null;
  private querySubmitCallback: QuerySubmitCallback | null = null;

  setQuerySubmitCallback(callback: QuerySubmitCallback): void {
    this.querySubmitCallback = callback;
  }

  setSchedulesPath(path: string): void {
    this.schedulesPath = path;
    this.loadTasks();
  }

  start(): void {
    if (this.isRunning) {
      return;
    }
    this.isRunning = true;
    this.scheduleAllTasks();
  }

  stop(): void {
    this.isRunning = false;
    this.timers.forEach((timer) => clearTimeout(timer));
    this.timers.clear();
  }

  addTask(params: ScheduleTaskParams): ScheduledTask {
    const id = crypto.randomUUID();
    const task: ScheduledTask = {
      id,
      name: params.name,
      description: params.description || '',
      cronExpression: params.cronExpression,
      command: params.command,
      prompt: params.prompt,
      taskType: params.taskType || (params.command ? 'shell' : 'qwen'),
      enabled: true,
      runCount: 0,
      maxRuns: params.maxRuns,
    };

    this.tasks.set(id, task);
    this.saveTasks();

    if (this.isRunning) {
      this.scheduleTask(task);
    }

    return task;
  }

  removeTask(id: string): boolean {
    const task = this.tasks.get(id);
    if (!task) {
      return false;
    }

    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }

    this.tasks.delete(id);
    this.saveTasks();
    return true;
  }

  getTask(id: string): ScheduledTask | undefined {
    return this.tasks.get(id);
  }

  getAllTasks(): ScheduledTask[] {
    return Array.from(this.tasks.values());
  }

  updateTask(id: string, updates: Partial<ScheduleTaskParams>): ScheduledTask | undefined {
    const task = this.tasks.get(id);
    if (!task) {
      return undefined;
    }

    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }

    Object.assign(task, updates);
    this.saveTasks();

    if (this.isRunning && task.enabled) {
      this.scheduleTask(task);
    }

    return task;
  }

  enableTask(id: string): boolean {
    const task = this.tasks.get(id);
    if (!task) {
      return false;
    }

    task.enabled = true;
    this.saveTasks();

    if (this.isRunning) {
      this.scheduleTask(task);
    }

    return true;
  }

  disableTask(id: string): boolean {
    const task = this.tasks.get(id);
    if (!task) {
      return false;
    }

    task.enabled = false;

    const timer = this.timers.get(id);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(id);
    }

    this.saveTasks();
    return true;
  }

  private scheduleAllTasks(): void {
    this.tasks.forEach((task) => {
      if (task.enabled) {
        this.scheduleTask(task);
      }
    });
  }

  private scheduleTask(task: ScheduledTask): void {
    const delay = this.parseCronExpression(task.cronExpression);
    if (delay === null) {
      console.error(`Invalid cron expression for task "${task.name}": ${task.cronExpression}`);
      return;
    }

    task.nextRun = Date.now() + delay;

    const timer = setTimeout(async () => {
      await this.executeTask(task);
      if (task.enabled && this.isRunning) {
        this.scheduleTask(task);
      }
    }, delay);

    this.timers.set(task.id, timer);
  }

  private parseCronExpression(expr: string): number | null {
    const expr2 = expr.trim().toLowerCase();

    const starMatch = expr2.match(/^\*\/(\d+)(s|m|h)?$/);
    if (starMatch) {
      const num = parseInt(starMatch[1], 10);
      const unit = starMatch[2] || 'm';
      return this.convertToMilliseconds(num, unit);
    }

    const intervalMatch = expr2.match(/^(\d+)(s|m|h|d)$/);
    if (intervalMatch) {
      const num = parseInt(intervalMatch[1], 10);
      const unit = intervalMatch[2];
      return this.convertToMilliseconds(num, unit);
    }

    const cronMatch = expr2.match(/^(\d+)\s+(\d+)\s+\*\s+\*\s+\*$/);
    if (cronMatch) {
      const minute = parseInt(cronMatch[1], 10);
      const hour = parseInt(cronMatch[2], 10);
      return this.calculateNextCronExecution(minute, hour);
    }

    return null;
  }

  private convertToMilliseconds(value: number, unit: string): number {
    switch (unit) {
      case 's':
        return value * 1000;
      case 'm':
        return value * 60 * 1000;
      case 'h':
        return value * 60 * 60 * 1000;
      case 'd':
        return value * 24 * 60 * 60 * 1000;
      default:
        return value * 60 * 1000;
    }
  }

  private calculateNextCronExecution(minute: number, hour: number): number {
    const now = new Date();
    const target = new Date();

    target.setHours(hour, minute, 0, 0);

    if (target <= now) {
      target.setDate(target.getDate() + 1);
    }

    return target.getTime() - now.getTime();
  }

  private async executeTask(task: ScheduledTask): Promise<void> {
    try {
      task.lastRun = Date.now();
      task.runCount++;
      this.saveTasks();

      if (task.taskType === 'qwen' && task.prompt && this.querySubmitCallback) {
        await this.executeQwenTask(task);
      } else if (task.taskType === 'shell' && task.command) {
        await this.executeShellTask(task);
      }

      if (task.maxRuns !== undefined && task.runCount >= task.maxRuns) {
        console.log(`Task "${task.name}" has reached max runs (${task.maxRuns}), disabling...`);
        this.disableTask(task.id);
        return;
      }
    } catch (error) {
      console.error(`Error executing scheduled task "${task.name}":`, error);
    }
  }

  private async executeQwenTask(task: ScheduledTask): Promise<void> {
    if (!this.querySubmitCallback || !task.prompt) {
      console.error(`Cannot execute Qwen task "${task.name}": missing callback or prompt`);
      return;
    }

    console.log(`🤖 Executing Qwen task: ${task.name}`);
    await this.querySubmitCallback(task.prompt);
    console.log(`✅ Qwen task completed: ${task.name}`);
  }

  private async executeShellTask(task: ScheduledTask): Promise<void> {
    if (!task.command) {
      console.error(`Cannot execute shell task "${task.name}": missing command`);
      return;
    }

    console.log(`🔧 Executing shell task: ${task.name}`);
    const { execSync } = await import('node:child_process');
    try {
      const output = execSync(task.command, { encoding: 'utf-8' });
      console.log(`✅ Shell task completed: ${task.name}`);
      console.log(`Output: ${output.trim()}`);
    } catch (error) {
      console.error(`❌ Shell task failed: ${task.name}`);
      console.error(error);
    }
  }

  private saveTasks(): void {
    if (!this.schedulesPath) {
      return;
    }

    try {
      const tasksArray = Array.from(this.tasks.values());
      const dir = path.dirname(this.schedulesPath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      fs.writeFileSync(this.schedulesPath, JSON.stringify(tasksArray, null, 2));
    } catch (error) {
      console.error('Error saving tasks:', error);
    }
  }

  private loadTasks(): void {
    if (!this.schedulesPath) {
      return;
    }

    try {
      if (fs.existsSync(this.schedulesPath)) {
        const data = fs.readFileSync(this.schedulesPath, 'utf-8');
        const tasksArray = JSON.parse(data) as ScheduledTask[];
        this.tasks.clear();
        tasksArray.forEach((task) => {
          this.tasks.set(task.id, task);
        });
      }
    } catch (error) {
      console.error('Error loading tasks:', error);
    }
  }
}