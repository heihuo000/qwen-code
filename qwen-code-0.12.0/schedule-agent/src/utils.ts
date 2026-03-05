/**
 * @license
 * Copyright 2025 Qwen
 * SPDX-License-Identifier: Apache-2.0
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { execSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(color: string, message: string) {
  console.log(`${color}${message}${colors.reset}`);
}

function info(message: string) { log(colors.blue, message); }
function success(message: string) { log(colors.green, message); }
function warn(message: string) { log(colors.yellow, message); }
function error(message: string) { log(colors.red, message); }

function getNpmPackagePath(): string | null {
  try {
    return execSync('npm root -g', { encoding: 'utf8' }).trim();
  } catch {
    const localPath = join(process.cwd(), 'node_modules');
    return existsSync(localPath) ? localPath : null;
  }
}

function findQwenPackage(): string | null {
  const npmRoot = getNpmPackagePath();
  if (!npmRoot) return null;

  const candidates = [
    join(npmRoot, '@qwen-code/qwen-code'),
    join(npmRoot, 'qwen-code'),
    join(process.cwd(), 'node_modules', '@qwen-code/qwen-code'),
  ];

  for (const candidate of candidates) {
    if (existsSync(join(candidate, 'cli.js'))) {
      return candidate;
    }
  }
  return null;
}

function detectVersion(pkgPath: string): string {
  const pkgJsonPath = join(pkgPath, 'package.json');
  if (!existsSync(pkgJsonPath)) return 'unknown';
  const pkg = JSON.parse(readFileSync(pkgJsonPath, 'utf8'));
  return pkg.version || 'unknown';
}

function checkInstallation(pkgPath: string): { installed: boolean; version: string; issues: string[] } {
  const cliPath = join(pkgPath, 'cli.js');
  const content = readFileSync(cliPath, 'utf8');
  const issues: string[] = [];

  const checks = [
    { name: 'SchedulerService', pattern: 'SchedulerService', found: false },
    { name: 'ScheduleTool', pattern: 'ScheduleTool', found: false },
    { name: 'SCHEDULE in ToolNames', pattern: "SCHEDULE: 'schedule'", found: false },
    { name: 'SCHEDULE in ToolDisplayNames', pattern: "SCHEDULE: 'Schedule'", found: false },
    { name: 'schedulerService field', pattern: 'schedulerService = void 0', found: false },
    { name: 'getSchedulerService method', pattern: 'getSchedulerService()', found: false },
    { name: 'registerCoreTool(ScheduleTool', pattern: 'registerCoreTool(ScheduleTool', found: false },
  ];

  for (const check of checks) {
    check.found = content.includes(check.pattern);
    if (!check.found) {
      issues.push(`Missing: ${check.name}`);
    }
  }

  return {
    installed: checks.every(c => c.found),
    version: detectVersion(pkgPath),
    issues,
  };
}

function uninstall(pkgPath: string): boolean {
  const cliPath = join(pkgPath, 'cli.js');

  // 查找最新的备份文件
  const backupDir = dirname(cliPath);
  const backups = existsSync(backupDir)
    ? execSync(`ls -t ${backupDir}/cli.js.backup.* 2>/dev/null | head -1`, { encoding: 'utf8' }).trim()
    : '';

  if (!backups || !existsSync(backups)) {
    error('未找到备份文件，无法卸载');
    return false;
  }

  info(`恢复备份：${backups}`);
  writeFileSync(cliPath, readFileSync(backups));
  success('卸载成功！');
  return true;
}

function checkVersionCompatibility(version: string): { compatible: boolean; warnings: string[] } {
  const warnings: string[] = [];
  const major = parseInt(version.split('.')[0] || '0');
  const minor = parseInt(version.split('.')[1] || '0');

  // 版本兼容性检查
  if (major < 0 || (major === 0 && minor < 10)) {
    warnings.push(`版本 ${version} 可能过旧，建议使用 v0.10.0 或更高版本`);
  }

  if (major > 1) {
    warnings.push(`版本 ${version} 是主版本 1.x，补丁可能需要调整`);
  }

  return {
    compatible: warnings.length === 0,
    warnings,
  };
}

export {
  info,
  success,
  warn,
  error,
  findQwenPackage,
  detectVersion,
  checkInstallation,
  uninstall,
  checkVersionCompatibility,
};
