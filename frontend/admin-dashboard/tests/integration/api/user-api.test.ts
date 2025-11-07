import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'
import { login, logout, getUserInfo, getUserList, createUser, updateUser, deleteUser } from '@/api/user'
import { createTestData } from '../../utils/test-utils'

// 创建MSW服务器
const server = setupServer()

describe('User API Integration Tests', () => {
  beforeEach(() => {
    server.listen({ onUnhandledRequest: 'error' })
    vi.clearAllMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    server.close()
  })

  describe('Authentication', () => {
    it('should login successfully', async () => {
      const mockResponse = {
        code: 200,
        message: '登录成功',
        data: {
          token: 'mock-jwt-token',
          user: createTestData.user(),
          permissions: ['read', 'write', 'admin']
        }
      }

      server.use(
        http.post('/api/v1/auth/login', () => {
          return HttpResponse.json(mockResponse)
        })
      )

      const loginData = {
        username: 'testuser',
        password: 'password123'
      }

      const result = await login(loginData)

      expect(result).toEqual(mockResponse.data)
    })

    it('should handle login failure', async () => {
      const mockError = {
        code: 401,
        message: '用户名或密码错误',
        data: null
      }

      server.use(
        http.post('/api/v1/auth/login', () => {
          return HttpResponse.json(mockError, { status: 401 })
        })
      )

      const loginData = {
        username: 'wronguser',
        password: 'wrongpassword'
      }

      await expect(login(loginData)).rejects.toThrow()
    })

    it('should logout successfully', async () => {
      const mockResponse = {
        code: 200,
        message: '退出成功',
        data: null
      }

      server.use(
        http.post('/api/v1/auth/logout', () => {
          return HttpResponse.json(mockResponse)
        })
      )

      const result = await logout()

      expect(result).toBeNull()
    })

    it('should get user info', async () => {
      const mockUser = createTestData.user()
      const mockResponse = {
        code: 200,
        message: '获取成功',
        data: mockUser
      }

      server.use(
        http.get('/api/v1/users/me', () => {
          return HttpResponse.json(mockResponse)
        })
      )

      const result = await getUserInfo()

      expect(result).toEqual(mockUser)
    })
  })

  describe('User Management', () => {
    it('should get user list with pagination', async () => {
      const mockUsers = [
        createTestData.user({ id: 1, username: 'user1' }),
        createTestData.user({ id: 2, username: 'user2' }),
        createTestData.user({ id: 3, username: 'user3' })
      ]

      const mockResponse = {
        code: 200,
        message: '获取成功',
        data: {
          items: mockUsers,
          pagination: {
            page: 1,
            pageSize: 10,
            total: 3,
            totalPages: 1
          }
        }
      }

      server.use(
        http.get('/api/v1/users', ({ request }) => {
          const url = new URL(request.url)
          const page = url.searchParams.get('page')
          const pageSize = url.searchParams.get('pageSize')
          
          expect(page).toBe('1')
          expect(pageSize).toBe('10')
          
          return HttpResponse.json(mockResponse)
        })
      )

      const params = {
        page: 1,
        pageSize: 10,
        search: ''
      }

      const result = await getUserList(params)

      expect(result.items).toEqual(mockUsers)
      expect(result.pagination.total).toBe(3)
    })

    it('should search users', async () => {
      const searchQuery = 'test'
      const mockUsers = [
        createTestData.user({ id: 1, username: 'testuser' })
      ]

      const mockResponse = {
        code: 200,
        message: '获取成功',
        data: {
          items: mockUsers,
          pagination: {
            page: 1,
            pageSize: 10,
            total: 1,
            totalPages: 1
          }
        }
      }

      server.use(
        http.get('/api/v1/users', ({ request }) => {
          const url = new URL(request.url)
          const search = url.searchParams.get('search')
          
          expect(search).toBe(searchQuery)
          
          return HttpResponse.json(mockResponse)
        })
      )

      const params = {
        page: 1,
        pageSize: 10,
        search: searchQuery
      }

      const result = await getUserList(params)

      expect(result.items).toHaveLength(1)
      expect(result.items[0].username).toBe('testuser')
    })

    it('should create user', async () => {
      const newUser = createTestData.user({ id: 4, username: 'newuser' })
      const createData = {
        username: 'newuser',
        email: 'newuser@example.com',
        role: 'user',
        password: 'password123'
      }

      const mockResponse = {
        code: 200,
        message: '创建成功',
        data: newUser
      }

      server.use(
        http.post('/api/v1/users', async ({ request }) => {
          const body = await request.json()
          
          expect(body).toEqual(createData)
          
          return HttpResponse.json(mockResponse)
        })
      )

      const result = await createUser(createData)

      expect(result).toEqual(newUser)
    })

    it('should update user', async () => {
      const userId = 1
      const updateData = {
        username: 'updateduser',
        email: 'updated@example.com'
      }
      const updatedUser = createTestData.user({ id: userId, ...updateData })

      const mockResponse = {
        code: 200,
        message: '更新成功',
        data: updatedUser
      }

      server.use(
        http.put(`/api/v1/users/${userId}`, async ({ request }) => {
          const body = await request.json()
          
          expect(body).toEqual(updateData)
          
          return HttpResponse.json(mockResponse)
        })
      )

      const result = await updateUser(userId, updateData)

      expect(result).toEqual(updatedUser)
    })

    it('should delete user', async () => {
      const userId = 1

      const mockResponse = {
        code: 200,
        message: '删除成功',
        data: null
      }

      server.use(
        http.delete(`/api/v1/users/${userId}`, () => {
          return HttpResponse.json(mockResponse)
        })
      )

      const result = await deleteUser(userId)

      expect(result).toBeNull()
    })
  })

  describe('Error Handling', () => {
    it('should handle network errors', async () => {
      server.use(
        http.get('/api/v1/users', () => {
          return HttpResponse.error()
        })
      )

      const params = {
        page: 1,
        pageSize: 10,
        search: ''
      }

      await expect(getUserList(params)).rejects.toThrow()
    })

    it('should handle server errors', async () => {
      const mockError = {
        code: 500,
        message: '服务器内部错误',
        data: null
      }

      server.use(
        http.get('/api/v1/users', () => {
          return HttpResponse.json(mockError, { status: 500 })
        })
      )

      const params = {
        page: 1,
        pageSize: 10,
        search: ''
      }

      await expect(getUserList(params)).rejects.toThrow()
    })

    it('should handle validation errors', async () => {
      const mockError = {
        code: 400,
        message: '参数验证失败',
        data: {
          errors: {
            username: '用户名不能为空',
            email: '邮箱格式不正确'
          }
        }
      }

      server.use(
        http.post('/api/v1/users', () => {
          return HttpResponse.json(mockError, { status: 400 })
        })
      )

      const createData = {
        username: '',
        email: 'invalid-email',
        role: 'user',
        password: 'password123'
      }

      await expect(createUser(createData)).rejects.toThrow()
    })
  })

  describe('Request Headers', () => {
    it('should include authorization header when token exists', async () => {
      // Mock localStorage to return a token
      vi.mocked(localStorage.getItem).mockReturnValue('mock-token')

      server.use(
        http.get('/api/v1/users/me', ({ request }) => {
          const authHeader = request.headers.get('Authorization')
          expect(authHeader).toBe('Bearer mock-token')
          
          return HttpResponse.json({
            code: 200,
            message: '获取成功',
            data: createTestData.user()
          })
        })
      )

      await getUserInfo()
    })

    it('should include request ID header', async () => {
      server.use(
        http.get('/api/v1/users/me', ({ request }) => {
          const requestId = request.headers.get('X-Request-ID')
          expect(requestId).toMatch(/^req_\d+_[a-z0-9]+$/)
          
          return HttpResponse.json({
            code: 200,
            message: '获取成功',
            data: createTestData.user()
          })
        })
      )

      await getUserInfo()
    })
  })
})









