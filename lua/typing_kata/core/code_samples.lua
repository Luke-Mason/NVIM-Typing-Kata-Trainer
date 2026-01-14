-- Collection of code samples for various game modes
local M = {}

M.samples = {
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

return M
