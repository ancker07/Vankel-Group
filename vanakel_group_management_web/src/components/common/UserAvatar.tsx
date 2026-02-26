
import React from 'react';

interface UserAvatarProps {
    name: string;
    size?: 'sm' | 'md' | 'lg' | 'xl';
    className?: string;
}

const UserAvatar: React.FC<UserAvatarProps> = ({ name, size = 'md', className = '' }) => {
    const initials = name
        .split(' ')
        .map(n => n[0])
        .join('')
        .toUpperCase()
        .slice(0, 2);

    // Generate a seeded color based on name
    const getGradient = (str: string) => {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }

        const h1 = Math.abs(hash % 360);
        const h2 = (h1 + 40) % 360;

        return `linear-gradient(135deg, hsl(${h1}, 70%, 60%), hsl(${h2}, 80%, 40%))`;
    };

    const sizeClasses = {
        sm: 'w-8 h-8 text-[10px]',
        md: 'w-10 h-10 text-xs',
        lg: 'w-14 h-14 text-sm',
        xl: 'w-20 h-20 text-xl',
    };

    return (
        <div
            className={`rounded-full flex items-center justify-center font-black text-white shadow-lg ${sizeClasses[size]} ${className}`}
            style={{ background: getGradient(name) }}
        >
            {initials}
        </div>
    );
};

export default UserAvatar;
