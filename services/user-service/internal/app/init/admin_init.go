package init

import (
	"context"
	"log"

	"github.com/google/uuid"
	"github.com/llmops/user-service/internal/domain/entity"
	"github.com/llmops/user-service/internal/domain/repository"
	"golang.org/x/crypto/bcrypt"
)

// AdminInitService 管理员初始化服务
type AdminInitService struct {
	userRepo      repository.UserRepository
	groupRepo     repository.UserGroupRepository
	userGroupRepo repository.UserGroupRepository
}

// NewAdminInitService 创建管理员初始化服务
func NewAdminInitService(
	userRepo repository.UserRepository,
	groupRepo repository.UserGroupRepository,
	userGroupRepo repository.UserGroupRepository,
) *AdminInitService {
	return &AdminInitService{
		userRepo:      userRepo,
		groupRepo:     groupRepo,
		userGroupRepo: userGroupRepo,
	}
}

// InitializeAdminUser 初始化admin用户和用户组
func (s *AdminInitService) InitializeAdminUser(ctx context.Context) error {
	// 1. 确保admin用户存在
	adminUserID := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	tenantID := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	
	// 检查admin用户是否存在
	existingUser, err := s.userRepo.GetByID(ctx, adminUserID)
	if err != nil || existingUser == nil {
		// 创建admin用户
		hashedPassword, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
		if err != nil {
			return err
		}

		adminUser := &entity.User{
			ID:       adminUserID.String(),
			Username: "admin",
			Email:    "admin@example.com",
			Password: string(hashedPassword),
			Name:     "Administrator",
			Status:   "active",
			TenantID: tenantID.String(),
		}

		if err := s.userRepo.Create(ctx, adminUser); err != nil {
			log.Printf("创建admin用户失败: %v", err)
			return err
		}
		log.Println("Admin用户创建成功")
	} else {
		log.Println("Admin用户已存在")
	}

	// 2. 确保管理员用户组存在
	adminGroupID := uuid.MustParse("00000000-0000-0000-0000-000000000002")
	
	existingGroup, err := s.groupRepo.GetByID(ctx, adminGroupID)
	if err != nil || existingGroup == nil {
		// 创建管理员用户组
		adminGroup := &entity.UserGroup{
			ID:          adminGroupID.String(),
			Name:        "管理员组",
			Description: "系统管理员组",
			TenantID:    tenantID.String(),
		}

		if err := s.groupRepo.Create(ctx, adminGroup); err != nil {
			log.Printf("创建管理员用户组失败: %v", err)
			return err
		}
		log.Println("管理员用户组创建成功")
	} else {
		log.Println("管理员用户组已存在")
	}

	// 3. 确保admin用户在管理员组中
	exists, err := s.userGroupRepo.CheckUserInGroup(ctx, adminUserID, adminGroupID)
	if err != nil {
		log.Printf("检查用户组成员关系失败: %v", err)
		return err
	}

	if !exists {
		// 将admin用户添加到管理员组
		if err := s.userGroupRepo.AddMember(ctx, adminUserID, adminGroupID, "admin"); err != nil {
			log.Printf("将admin用户添加到管理员组失败: %v", err)
			return err
		}
		log.Println("Admin用户已添加到管理员组")
	} else {
		log.Println("Admin用户已在管理员组中")
	}

	// 4. 更新用户组成员数量
	members, err := s.userGroupRepo.GetMembers(ctx, adminGroupID)
	if err != nil {
		log.Printf("获取用户组成员失败: %v", err)
		return err
	}

	// 更新用户组的成员数量
	adminGroup, err := s.groupRepo.GetByID(ctx, adminGroupID)
	if err != nil {
		log.Printf("获取管理员用户组失败: %v", err)
		return err
	}

	adminGroup.MemberCount = len(members)
	if err := s.groupRepo.Update(ctx, adminGroup); err != nil {
		log.Printf("更新用户组成员数量失败: %v", err)
		return err
	}

	log.Printf("管理员用户组成员数量已更新: %d", len(members))
	return nil
}

// EnsureAdminUserInAdminGroup 确保admin用户在管理员组中
func (s *AdminInitService) EnsureAdminUserInAdminGroup(ctx context.Context) error {
	adminUserID := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	adminGroupID := uuid.MustParse("00000000-0000-0000-0000-000000000002")

	// 检查admin用户是否在管理员组中
	exists, err := s.userGroupRepo.CheckUserInGroup(ctx, adminUserID, adminGroupID)
	if err != nil {
		return err
	}

	if !exists {
		// 将admin用户添加到管理员组
		if err := s.userGroupRepo.AddMember(ctx, adminUserID, adminGroupID, "admin"); err != nil {
			return err
		}
		log.Println("Admin用户已添加到管理员组")
	}

	return nil
}

// GetAdminUserGroupInfo 获取admin用户组信息
func (s *AdminInitService) GetAdminUserGroupInfo(ctx context.Context) (*entity.UserGroup, []*entity.UserGroupMember, error) {
	adminGroupID := uuid.MustParse("00000000-0000-0000-0000-000000000002")

	// 获取管理员用户组信息
	group, err := s.groupRepo.GetByID(ctx, adminGroupID)
	if err != nil {
		return nil, nil, err
	}

	// 获取管理员用户组成员
	members, err := s.userGroupRepo.GetMembers(ctx, adminGroupID)
	if err != nil {
		return nil, nil, err
	}

	return group, members, nil
}
