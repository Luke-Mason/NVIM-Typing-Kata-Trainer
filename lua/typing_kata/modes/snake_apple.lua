-- Snake Apple Mode: Navigate code with real vim motions to find apples
local BaseMode = require('typing_kata.modes.base_mode')
local buffer_utils = require('typing_kata.ui.buffer')
local session = require('typing_kata.core.session')
local xp_module = require('typing_kata.core.xp')

local SnakeApple = setmetatable({}, { __index = BaseMode })

-- Code samples in different languages
SnakeApple.CODE_SAMPLES = {
  {
    filetype = "go",
    name = "user_service.go",
    code = [[
package main

import (
    "fmt"
    "time"
)

type UserService struct {
    repository UserRepository
    cache      CacheManager
    logger     Logger
}

func NewUserService(repo UserRepository, cache CacheManager) *UserService {
    return &UserService{
        repository: repo,
        cache:      cache,
        logger:     NewLogger("UserService"),
    }
}

func (s *UserService) GetUser(userID string) (*User, error) {
    // Check cache first
    if cached := s.cache.Get(userID); cached != nil {
        return cached.(*User), nil
    }

    // Fetch from repository
    user, err := s.repository.FindByID(userID)
    if err != nil {
        s.logger.Error("Failed to fetch user", err)
        return nil, err
    }

    // Update cache
    s.cache.Set(userID, user, 5*time.Minute)
    return user, nil
}

func (s *UserService) CreateUser(email string, password string) error {
    hashedPassword := hashPassword(password)
    user := &User{
        Email:    email,
        Password: hashedPassword,
        Created:  time.Now(),
    }

    if err := s.repository.Save(user); err != nil {
        return fmt.Errorf("failed to create user: %w", err)
    }

    return nil
}

func (s *UserService) ValidateCredentials(email, password string) bool {
    user, err := s.repository.FindByEmail(email)
    if err != nil {
        return false
    }
    return checkPassword(user.Password, password)
}
]]
  },
  {
    filetype = "python",
    name = "data_processor.py",
    code = [[
import pandas as pd
import numpy as np
from typing import List, Dict, Optional
from dataclasses import dataclass

@dataclass
class ProcessingConfig:
    batch_size: int
    threshold: float
    normalize: bool = True

class DataProcessor:
    def __init__(self, config: ProcessingConfig):
        self.config = config
        self.results = []

    def process_batch(self, data: pd.DataFrame) -> pd.DataFrame:
        """Process a batch of data with normalization and filtering."""
        if self.config.normalize:
            data = self._normalize(data)

        filtered = data[data['value'] > self.config.threshold]
        return filtered

    def _normalize(self, data: pd.DataFrame) -> pd.DataFrame:
        """Normalize data using z-score normalization."""
        return (data - data.mean()) / data.std()

    def aggregate_results(self, groups: List[str]) -> Dict[str, float]:
        """Aggregate results by specified groups."""
        aggregated = {}
        for group in groups:
            values = [r[group] for r in self.results if group in r]
            aggregated[group] = np.mean(values) if values else 0.0
        return aggregated

    def export_summary(self, filepath: str) -> None:
        """Export processing summary to file."""
        summary = {
            'total_processed': len(self.results),
            'config': self.config.__dict__,
            'timestamp': pd.Timestamp.now().isoformat()
        }

        with open(filepath, 'w') as f:
            json.dump(summary, f, indent=2)

def create_processor(batch_size: int = 100) -> DataProcessor:
    config = ProcessingConfig(
        batch_size=batch_size,
        threshold=0.5,
        normalize=True
    )
    return DataProcessor(config)
]]
  },
  {
    filetype = "javascript",
    name = "api_client.js",
    code = [[
import axios from 'axios';
import { logger } from './logger';
import { retry } from './utils';

class ApiClient {
  constructor(baseURL, apiKey) {
    this.baseURL = baseURL;
    this.apiKey = apiKey;
    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: 5000,
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });
  }

  async get(endpoint, params = {}) {
    try {
      const response = await retry(() =>
        this.client.get(endpoint, { params })
      );
      return response.data;
    } catch (error) {
      logger.error(`GET ${endpoint} failed:`, error);
      throw new ApiError(error.message, error.response?.status);
    }
  }

  async post(endpoint, data) {
    try {
      const response = await this.client.post(endpoint, data);
      logger.info(`POST ${endpoint} succeeded`);
      return response.data;
    } catch (error) {
      logger.error(`POST ${endpoint} failed:`, error);
      throw new ApiError(error.message, error.response?.status);
    }
  }

  async delete(endpoint) {
    try {
      await this.client.delete(endpoint);
      logger.info(`DELETE ${endpoint} succeeded`);
      return true;
    } catch (error) {
      logger.error(`DELETE ${endpoint} failed:`, error);
      return false;
    }
  }

  setAuthToken(token) {
    this.client.defaults.headers['Authorization'] = `Bearer ${token}`;
  }
}

export function createClient(config) {
  return new ApiClient(config.baseURL, config.apiKey);
}

export class ApiError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
  }
}
]]
  },
  {
    filetype = "yaml",
    name = "kubernetes.yaml",
    code = [[
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: production
  labels:
    app: web
    tier: frontend
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
      protocol: TCP
      name: http
  selector:
    app: web
    tier: frontend
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
      tier: frontend
  template:
    metadata:
      labels:
        app: web
        tier: frontend
    spec:
      containers:
      - name: web
        image: myapp:1.2.3
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        - name: API_KEY
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: api-key
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  api-key: "prod-api-key-12345"
  environment: "production"
  log-level: "info"
]]
  },
  {
    filetype = "rust",
    name = "message_queue.rs",
    code = [[
use std::collections::VecDeque;
use std::sync::{Arc, Mutex};
use tokio::sync::Notify;

pub struct MessageQueue<T> {
    queue: Arc<Mutex<VecDeque<T>>>,
    notify: Arc<Notify>,
    capacity: usize,
}

impl<T> MessageQueue<T> {
    pub fn new(capacity: usize) -> Self {
        Self {
            queue: Arc::new(Mutex::new(VecDeque::new())),
            notify: Arc::new(Notify::new()),
            capacity,
        }
    }

    pub async fn push(&self, item: T) -> Result<(), QueueError> {
        let mut queue = self.queue.lock().unwrap();

        if queue.len() >= self.capacity {
            return Err(QueueError::Full);
        }

        queue.push_back(item);
        self.notify.notify_one();
        Ok(())
    }

    pub async fn pop(&self) -> Option<T> {
        loop {
            {
                let mut queue = self.queue.lock().unwrap();
                if let Some(item) = queue.pop_front() {
                    return Some(item);
                }
            }

            self.notify.notified().await;
        }
    }

    pub fn len(&self) -> usize {
        self.queue.lock().unwrap().len()
    }

    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

#[derive(Debug)]
pub enum QueueError {
    Full,
    Closed,
}

impl std::fmt::Display for QueueError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            QueueError::Full => write!(f, "Queue is full"),
            QueueError::Closed => write!(f, "Queue is closed"),
        }
    }
}
]]
  },
}

function SnakeApple:new(player)
  local obj = BaseMode:new(player, 'snake_apple')
  setmetatable(obj, { __index = self })

  obj.apples_per_round = 5  -- 5 apples per code file
  obj.rounds_per_session = 3  -- 3 different code files
  obj.current_round = 1
  obj.apples_found = 0
  obj.total_apples_found = 0

  obj.apple_positions = {}  -- Store line numbers where apples are hidden
  obj.buffer_lines = {}
  obj.current_sample = nil
  obj.autocmd_id = nil
  obj.first_render = true  -- Track if this is the first render

  return obj
end

function SnakeApple:setup()
  -- Nothing special
end

function SnakeApple:generate_task()
  if self.current_round > self.rounds_per_session then
    -- Session complete
    self:exit()
    return
  end

  -- Pick random code sample
  self.current_sample = self.CODE_SAMPLES[math.random(#self.CODE_SAMPLES)]

  -- Split code into lines
  self.buffer_lines = {}
  for line in self.current_sample.code:gmatch("[^\r\n]+") do
    table.insert(self.buffer_lines, line)
  end

  -- Pick 5 random lines to hide apples (avoid empty lines and first/last few lines)
  self.apple_positions = {}
  local valid_lines = {}
  for i = 5, #self.buffer_lines - 5 do
    local line = self.buffer_lines[i]
    -- Only pick lines with actual content (not just whitespace/braces)
    if line:match("%S") and #line > 10 then
      table.insert(valid_lines, i)
    end
  end

  -- Pick 5 random positions
  if #valid_lines >= 5 then
    local used = {}
    for i = 1, self.apples_per_round do
      local idx
      repeat
        idx = math.random(1, #valid_lines)
      until not used[idx]
      used[idx] = true

      local line_num = valid_lines[idx]
      table.insert(self.apple_positions, line_num)

      -- Insert apple at a random word position in the line
      local line = self.buffer_lines[line_num]
      local words = {}
      local positions = {}
      local current_pos = 1

      -- Find all word positions
      for word in line:gmatch("%S+") do
        local start = line:find(word, current_pos, true)
        if start then
          table.insert(words, word)
          table.insert(positions, start)
          current_pos = start + #word
        end
      end

      if #words > 0 then
        -- Pick a word in the middle (not first or last)
        local word_idx = math.random(math.max(2, math.floor(#words * 0.3)), math.min(#words - 1, math.floor(#words * 0.7)))
        local insert_pos = positions[word_idx]

        -- Insert apple emoji before the word
        self.buffer_lines[line_num] = line:sub(1, insert_pos - 1) .. "🍎 " .. line:sub(insert_pos)
      end
    end
  end

  self.apples_found = 0
end

function SnakeApple:create_buffer()
  BaseMode.create_buffer(self)
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
  vim.api.nvim_win_set_option(0, 'wrap', false)
end

function SnakeApple:setup_buffer_keymaps()
  local opts = { buffer = self.buffer, noremap = true, silent = true }

  vim.keymap.set('n', 'q', function() self:exit() end, opts)
  vim.keymap.set('n', '<Esc>', function() self:exit() end, opts)

  self.autocmd_id = vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = self.buffer,
    callback = function()
      self:on_cursor_move()
    end
  })
end

function SnakeApple:on_cursor_move()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  -- Account for header (5 lines)
  local code_line = row - 5

  if code_line > 0 and code_line <= #self.buffer_lines then
    local line = self.buffer_lines[code_line]

    -- Check if this line has an apple
    if line and line:find("🍎") then
      -- Find the exact byte position of the apple in the line
      local apple_start, apple_end = line:find("🍎")

      if apple_start then
        -- The emoji 🍎 is 4 bytes in UTF-8
        -- Check if cursor is within the first byte of the emoji only
        -- apple_start is 1-indexed in Lua, col is 0-indexed in Neovim
        if col == apple_start - 1 then
          -- Check if this apple hasn't been collected yet
          for _, found_line in ipairs(self.apple_positions) do
            if found_line == code_line then
              -- Replace apple with a space
              self.buffer_lines[code_line] = line:gsub("🍎", " ", 1)

              self.apples_found = self.apples_found + 1
              self.total_apples_found = self.total_apples_found + 1

              -- Award XP
              local xp = self:calculate_xp()
              session.add_task_completion(self.session, xp)
              session.increment_streak(self.session)

              vim.notify(string.format('🍎 Apple %d/%d found! (+%d XP)',
                self.apples_found, self.apples_per_round, xp), vim.log.levels.INFO)

              -- Update the buffer line without re-rendering entire buffer
              local buffer_line_num = row
              vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
              vim.api.nvim_buf_set_lines(self.buffer, buffer_line_num - 1, buffer_line_num, false, {self.buffer_lines[code_line]})
              vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)

              -- Check if round complete
              if self.apples_found >= self.apples_per_round then
                vim.defer_fn(function()
                  if self.is_running then
                    self.current_round = self.current_round + 1
                    if self.current_round <= self.rounds_per_session then
                      vim.notify('Round complete! New code file loaded...', vim.log.levels.INFO)
                      self.first_render = true  -- Reset cursor position for new round
                      self:generate_task()
                      self:render()
                    else
                      self:exit()
                    end
                  end
                end, 1000)
              end

              break
            end
          end
        end
      end
    end
  end

  self:update_header()
end

function SnakeApple:update_header()
  if not self.buffer or not vim.api.nvim_buf_is_valid(self.buffer) then
    return
  end

  local stats_line = string.format('🐍 %s | Round: %d/%d | Apples: %d/%d | Total: %d | Streak: %d | XP: %d',
    self.current_sample.name,
    self.current_round, self.rounds_per_session,
    self.apples_found, self.apples_per_round,
    self.total_apples_found,
    self.session.current_streak, self.session.xp_earned)

  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.buffer, 1, 2, false, {stats_line})
  vim.api.nvim_buf_set_option(self.buffer, 'modifiable', true)
end

function SnakeApple:update(key)
  return false
end

function SnakeApple:render()
  if not self.current_sample then
    return
  end

  local lines = {}

  -- Header
  table.insert(lines, '')
  table.insert(lines, string.format('🐍 %s | Round: %d/%d | Apples: %d/%d | Total: %d | Streak: %d | XP: %d',
    self.current_sample.name,
    self.current_round, self.rounds_per_session,
    self.apples_found, self.apples_per_round,
    self.total_apples_found,
    self.session.current_streak, self.session.xp_earned))
  table.insert(lines, '')
  table.insert(lines, 'Navigate code to find 5 hidden 🍎 apples! Use: %%, ]], [[, {}, /🍎, f🍎, w/b/e, etc.')
  table.insert(lines, '')

  -- Add code with apples
  for _, line in ipairs(self.buffer_lines) do
    table.insert(lines, line)
  end

  table.insert(lines, '')

  -- Add consistent controls legend
  local controls = self:render_controls_legend({
    {key = 'Vim Motions', desc = 'Navigate to find apples (h/j/k/l, w/b/e, %%, ]], [[, {}, f🍎, /🍎, etc.)'},
    {key = 'ESC', desc = 'Exit to menu'},
  })
  for _, line in ipairs(controls) do
    table.insert(lines, line)
  end

  buffer_utils.set_content(self.buffer, lines)

  -- Set filetype for syntax highlighting
  vim.api.nvim_buf_set_option(self.buffer, 'filetype', self.current_sample.filetype)

  -- Only position cursor on first render or when loading new round
  if self.first_render then
    vim.api.nvim_win_set_cursor(0, {6, 0})
    self.first_render = false
  end
end

function SnakeApple:calculate_xp()
  local base_xp = 10
  return xp_module.calculate(base_xp, {
    accuracy = 100,
    streak = self.session.current_streak,
  })
end

function SnakeApple:exit()
  if self.autocmd_id then
    vim.api.nvim_del_autocmd(self.autocmd_id)
  end

  vim.api.nvim_win_set_option(0, 'wrap', true)
  BaseMode.exit(self)
end

return SnakeApple
