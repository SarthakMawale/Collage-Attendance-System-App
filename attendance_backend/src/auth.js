// attendance_backend/src/auth.js
const jwt = require('jsonwebtoken');
require('dotenv').config();

// ✅ JWT_SECRET ko properly define karein
const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error('❌ JWT_SECRET is not defined in .env file!');
    console.error('⚠️ Please add JWT_SECRET to your .env file');
    // Fallback for development - BUT DON'T USE IN PRODUCTION
    // JWT_SECRET = 'your-super-secret-key-change-this-in-production';
    process.exit(1);
}
console.log('✅ JWT_SECRET loaded successfully');

function signToken(user, expiresIn = '30d') {
    if (!user || !user.id) {
        throw new Error('Invalid user object for token signing');
    }

    return jwt.sign(
        {
            id: user.id,
            role: user.role,
            isSuperAdmin: user.is_super_admin || false,
        },
        JWT_SECRET,
        { expiresIn: expiresIn }
    );
}

function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (!token) {
        return res.status(401).json({
            error: 'Authentication required. Please login.',
            code: 'MISSING_TOKEN',
        });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        if (!decoded.id || !decoded.role) {
            return res.status(401).json({
                error: 'Invalid token structure',
                code: 'INVALID_TOKEN',
            });
        }
        req.user = decoded;
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({
                error: 'Session expired. Please login again.',
                code: 'TOKEN_EXPIRED',
            });
        }
        return res.status(401).json({
            error: 'Invalid token. Please login again.',
            code: 'INVALID_TOKEN',
        });
    }
}

function requireRole(...roles) {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                error: 'Authentication required',
                code: 'NOT_AUTHENTICATED',
            });
        }

        if (req.user.isSuperAdmin) {
            return next();
        }

        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                error: `Access denied. Required role: ${roles.join(' or ')}`,
                code: 'INSUFFICIENT_ROLE',
                userRole: req.user.role,
            });
        }

        next();
    };
}

// ✅ JWT_SECRET ko export karein
module.exports = { signToken, requireAuth, requireRole, JWT_SECRET };